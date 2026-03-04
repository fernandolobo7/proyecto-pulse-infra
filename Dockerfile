# 1. Usamos Python como base
FROM python:3.9-slim

# 2. Creamos una carpeta para la app dentro de Docker
WORKDIR /app

# 3. Copiamos tu archivo app.py a esa carpeta
COPY app.py .

# 4. Instalamos la librería de Prometheus (la que usa tu código)
RUN pip install prometheus_client requests

# 5. Exponemos el puerto 8000
EXPOSE 8000

# 6. Comando para arrancar tu app
CMD ["python", "app.py"]