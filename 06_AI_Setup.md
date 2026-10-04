# Install OLLAMA
winget install Ollama.Ollama

Ollama – https://ollama.com/
nginx – https://nginx.org/
mkcert – https://github.com/FiloSottile/mkcert



# NGINX installieren
https://nginx.org/en/download.html

# Installation mkcert
winget install FiloSottile.mkcert

--lokale CA installieren
mkcert -install
dir C:\Users\<YOUR USERNAME>\AppData\Local\mkcert\rootCA.pem


md c:\certs

hier ausführen: 
mkcert <YOUR IP ADDRESS> localhost 127.0.0.1 ::1
mkcert 192.168.100.4 localhost 127.0.0.1 ::1


# im Nginx Ordner die nginx.conf anpassen

--NGINX Installationsordner: nginx.conf Datei ersetzen durch:
--------------------------------------------------------
http {
    server {
        listen 443 ssl;
        server_name <YOUR IP ADDRESS HERE>;

        ssl_certificate      ../certs/<YOUR CERT FILENAME HERE>.pem;
        ssl_certificate_key  ../certs/<YOUR CERT FILENAME HERE>-key.pem;

        location / {
            proxy_pass http://localhost:11434;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
--------------------------------------------------------

ngnix -s stop
start nginx 

----ALTERNATIVE über OPENSSL----------------------------

# Verzeichnis für Zertifikat e erstellen
Skript dort ausführen --> ..\..\certs\createCert.ps1
Angaben:
## DNS = localhost
## Password: ppedv2026!
## Filepath: c:\certs\cert.pfx


# Open SSL installation
winget install ShiningLight.OpenSSL.Light
## In Umgebungsvariablem mitaufnehmen
$oldPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = $oldPath + ";C:\Program Files\OpenSSL-Win64\bin"
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
## Kontrolle e der Systemvariablen
rundll32 sysdm.cpl,EditEnvironmentVariables

## Zertifikat für nginx
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
## Konsole
cd \certs
openssl pkcs12 -in cert.pfx -nocerts -out cert.key -nodes
## Eingabe Kennwort...




## nginx conf anpassen
cd C:\nginx-1.29.4\conf
notepad nginx.conf

## Alles mit folgendem ersetzen
worker_processes auto;

events {
worker_connections 1024;
}

http {

upstream ollama {
server localhost:11434;
}

server {
listen 11435 ssl;
server_name localhost;

ssl_certificate C:\certs\cert.crt;
ssl_certificate_key C:\certs\cert.key;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers HIGH:!aNULL:!MD5;

location / {
proxy_pass http://localhost:11434;
proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Origin '';
proxy_set_header Referer '';
}
}
}
##
----ENDE ALTERNATIVE über OPENSSL----------------------------


## hosts datei anpassen
cd C:\Windows\System32\drivers\etc
notepad hosts
## Eintrag:  127.0.0.1 localhost


## OLLAMA
Set-Location -Path "C:\"
ollama pull nomic-embed-text
ollama serve


## Falls Fehler

$env:OLLAMA_HOST="127.0.0.1:11434"
ollama pull nomic-embed-text


## Nginx starten
cd C:\nginx-1.29.4
start nginx

Invoke-WebRequest -Uri "https://localhost:11435/api/embed" -ContentType "application/json" -Method POST -Body '{ "model":"nomic-embed-text", "prompt":"test text"}'

$env:OLLAMA_HOST="127.0.0.1"
ollama serve

# Beendet die App und den Server-Dienst
Stop-Process -Name "ollama*" -Force -ErrorAction SilentlyContinue

Get-NetTCPConnection -LocalPort 11435 -ErrorAction SilentlyContinue
$env:OLLAMA_HOST="localhost:11435"
ollama pull nomic-embed-text

Invoke-RestMethod -Uri "https://127.0.0.1:11435/api/tags"
Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags"

$env:OLLAMA_HOST="127.0.0.1:11434"
ollama pull nomic-embed-text