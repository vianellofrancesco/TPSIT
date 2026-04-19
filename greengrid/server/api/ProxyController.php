<?php

require_once __DIR__ . '/../config/database.php';

class ProxyController {

    /** Sostituire con la propria chiave Electricity Maps Free Tier. */
    private const API_KEY  = 'TUA_API_KEY';
    private const BASE_URL = 'https://api.electricitymap.org/v3/';
    private const TIMEOUT  = 10;

    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /** Dispatch delle sotto-azioni del proxy. */
    public function handle(string $method, ?string $action): void {
        if ($method !== 'GET') {
            http_response_code(405);
            echo json_encode(['error' => 'Metodo non consentito']);
            return;
        }

        switch ($action) {
            case 'zones':
                $this->zones();
                break;
            case 'carbon-intensity':
                $this->carbonIntensity();
                break;
            case 'power-breakdown':
                $this->powerBreakdown();
                break;
            case 'history':
                $this->history();
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Azione proxy non trovata']);
        }
    }

    private function zones(): void {
        $response = $this->callApi('zones');
        if ($response === null) return;
        echo json_encode($response);
    }

    private function carbonIntensity(): void {
        $zone = $this->requireZoneParam();
        if ($zone === null) return;

        $response = $this->callApi("carbon-intensity/latest?zone=" . urlencode($zone));
        if ($response === null) return;

        if ($this->isZoneMonitored($zone) && isset($response['datetime'])) {
            $this->insertReading([
                'zone_key'             => $zone,
                'carbon_intensity'     => $response['carbonIntensity'] ?? null,
                'renewable_percentage' => null,
                'fossil_percentage'    => null,
                'power_breakdown_json' => null,
                'reading_datetime'     => $this->normalizeDatetime($response['datetime']),
            ]);
        }

        echo json_encode($response);
    }

    private function powerBreakdown(): void {
        $zone = $this->requireZoneParam();
        if ($zone === null) return;

        $response = $this->callApi("power-breakdown/latest?zone=" . urlencode($zone));
        if ($response === null) return;

        if ($this->isZoneMonitored($zone) && isset($response['datetime'])) {
            $breakdown = $response['powerConsumptionBreakdown']
                      ?? $response['powerProductionBreakdown']
                      ?? null;
            $fossilFree = $response['fossilFreePercentage'] ?? null;

            $this->insertReading([
                'zone_key'             => $zone,
                'carbon_intensity'     => null,
                'renewable_percentage' => $response['renewablePercentage'] ?? null,
                'fossil_percentage'    => $fossilFree !== null ? (100 - $fossilFree) : null,
                'power_breakdown_json' => $breakdown !== null ? json_encode($breakdown) : null,
                'reading_datetime'     => $this->normalizeDatetime($response['datetime']),
            ]);
        }

        echo json_encode($response);
    }

    private function history(): void {
        $zone = $this->requireZoneParam();
        if ($zone === null) return;

        $response = $this->callApi("carbon-intensity/history?zone=" . urlencode($zone));
        if ($response === null) return;

        if ($this->isZoneMonitored($zone) && !empty($response['history'])) {
            foreach ($response['history'] as $entry) {
                if (!isset($entry['datetime'])) continue;
                $this->insertReading([
                    'zone_key'             => $zone,
                    'carbon_intensity'     => $entry['carbonIntensity'] ?? null,
                    'renewable_percentage' => null,
                    'fossil_percentage'    => null,
                    'power_breakdown_json' => null,
                    'reading_datetime'     => $this->normalizeDatetime($entry['datetime']),
                ]);
            }
        }

        echo json_encode($response);
    }

    
    private function callApi(string $path): ?array {
        $url = self::BASE_URL . $path;

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => self::TIMEOUT,
            CURLOPT_CONNECTTIMEOUT => self::TIMEOUT,
            CURLOPT_HTTPHEADER     => [
                'auth-token: ' . self::API_KEY,
                'Accept: application/json',
            ],
        ]);

        $body       = curl_exec($ch);
        $httpCode   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError  = curl_error($ch);
        curl_close($ch);

        if ($body === false || $curlError !== '') {
            http_response_code(502);
            echo json_encode(['error' => 'Errore di connessione all\'API esterna', 'detail' => $curlError]);
            return null;
        }

        if ($httpCode === 401) {
            http_response_code(401);
            echo json_encode(['error' => 'API key Electricity Maps non valida']);
            return null;
        }

        if ($httpCode < 200 || $httpCode >= 300) {
            http_response_code(502);
            echo json_encode([
                'error'     => 'Errore dall\'API esterna',
                'upstream'  => $httpCode,
                'response'  => json_decode($body, true) ?? $body,
            ]);
            return null;
        }

        $decoded = json_decode($body, true);
        if (!is_array($decoded)) {
            http_response_code(502);
            echo json_encode(['error' => 'Risposta non valida dall\'API esterna']);
            return null;
        }

        return $decoded;
    }

    private function requireZoneParam(): ?string {
        $zone = $_GET['zone'] ?? '';
        if (trim($zone) === '') {
            http_response_code(400);
            echo json_encode(['error' => 'Parametro "zone" obbligatorio']);
            return null;
        }
        return $zone;
    }

    private function isZoneMonitored(string $zoneKey): bool {
        $stmt = $this->db->prepare("SELECT 1 FROM zones_monitored WHERE zone_key = :zk");
        $stmt->execute([':zk' => $zoneKey]);
        return (bool)$stmt->fetch();
    }

    /**
     * Inserisce o aggiorna la lettura per (zone_key, reading_datetime).
     *
     * Comportamento di MERGE: se esiste già una riga con stessa zone+datetime,
     * aggiorna SOLO i campi non-null del nuovo set (via COALESCE), preservando
     * i dati salvati da chiamate precedenti. Questo è fondamentale perché i tre
     * endpoint proxy (carbon-intensity, power-breakdown, history) popolano
     * campi diversi della stessa riga logica: l'ordine delle chiamate non deve
     * causare perdita di dati.
     */
    private function insertReading(array $r): void {
        $check = $this->db->prepare(
            "SELECT id FROM carbon_readings
             WHERE zone_key = :zk AND reading_datetime = :dt
             LIMIT 1"
        );
        $check->execute([':zk' => $r['zone_key'], ':dt' => $r['reading_datetime']]);
        $existing = $check->fetch();

        if ($existing) {
            $stmt = $this->db->prepare(
                "UPDATE carbon_readings
                 SET carbon_intensity     = COALESCE(:ci, carbon_intensity),
                     renewable_percentage = COALESCE(:rp, renewable_percentage),
                     fossil_percentage    = COALESCE(:fp, fossil_percentage),
                     power_breakdown_json = COALESCE(:pb, power_breakdown_json)
                 WHERE id = :id"
            );
            $stmt->execute([
                ':ci' => $r['carbon_intensity'],
                ':rp' => $r['renewable_percentage'],
                ':fp' => $r['fossil_percentage'],
                ':pb' => $r['power_breakdown_json'],
                ':id' => $existing['id'],
            ]);
            return;
        }

        $stmt = $this->db->prepare(
            "INSERT INTO carbon_readings
                (zone_key, carbon_intensity, renewable_percentage, fossil_percentage,
                 power_breakdown_json, reading_datetime)
             VALUES
                (:zk, :ci, :rp, :fp, :pb, :dt)"
        );
        $stmt->execute([
            ':zk' => $r['zone_key'],
            ':ci' => $r['carbon_intensity'],
            ':rp' => $r['renewable_percentage'],
            ':fp' => $r['fossil_percentage'],
            ':pb' => $r['power_breakdown_json'],
            ':dt' => $r['reading_datetime'],
        ]);
    }

    /** "2025-04-19T10:00:00.000Z" → "2025-04-19 10:00:00" (DATETIME MySQL). */
    private function normalizeDatetime(string $iso): string {
        try {
            $dt = new DateTime($iso);
            return $dt->format('Y-m-d H:i:s');
        } catch (Exception $e) {
            return date('Y-m-d H:i:s');
        }
    }
}
