import time
import requests
import os
from prometheus_client import start_http_server, Histogram, Counter

# Configuración: URL que vamos a monitorear
TARGET_URL = os.getenv('TARGET_URL', 'https://www.google.com')
POLL_INTERVAL = int(os.getenv('POLL_INTERVAL', '5'))

# MÉTRICA PRO: Histograma para percentiles (p95/p99) solicitado por el instructor
LATENCY_HISTOGRAM = Histogram(
    'pulse_latency_seconds', 
    'Distribución de latencia hacia servicios externos',
    ['target'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
)

ERROR_COUNTER = Counter(
    'pulse_errors_total', 
    'Total de fallos de conexión detectados', 
    ['target']
)

def measure():
    print(f"PULSE Iniciado - Monitoreando: {TARGET_URL}")
    while True:
        try:
            start_time = time.time()
            response = requests.get(TARGET_URL, timeout=5)
            duration = time.time() - start_time
            
            # Guardamos el tiempo de respuesta en el histograma
            LATENCY_HISTOGRAM.labels(target=TARGET_URL).observe(duration)
            print(f"Latencia: {duration:.4f}s | Status: {response.status_code}")
            
        except Exception as e:
            print(f"Error de red detectado: {e}")
            ERROR_COUNTER.labels(target=TARGET_URL).inc()
            
        time.sleep(POLL_INTERVAL)

if __name__ == '__main__':
    # El puerto 8000 expondrá las métricas para Prometheus
    start_http_server(8000)
    measure()