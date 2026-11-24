To: google-cloud-compliance@google.com, network-abuse@google.com
Subject: Abuse Report: Automated Credential & Secret Scanning (GCP/Firebase, .env, .git) from 34.72.10.200

Hello Google Cloud Compliance / Abuse Team,

I am writing to report malicious automated vulnerability and credential-harvesting activity originating from a Google Cloud IP address belonging to your network (34.72.10.200).

We detected a burst of 248 automated HTTP requests (244 GET, 4 POST) within 43 seconds targeting our subdomain (prometheus.agsonhos.com.br), specifically probing for sensitive configuration files, source control metadata, server diagnostics, and Google Cloud / Firebase credentials (e.g., /.git/config, /.env.local, /production/.env, /service-account.json, /gcp-credentials.json, /.config/gcloud/application_default_credentials.json, /firebase-adminsdk.json, /info.php). All 248 requests were blocked at our CDN/WAF edge (HTTP 403).

Incident Details:
- Attacker IP: 34.72.10.200 (US - Google Cloud)
- Target Host: prometheus.agsonhos.com.br
- Date & Time (UTC): 2026-11-23 20:27:57 UTC to 2026-11-23 20:28:40 UTC
- Local Time Reference: 2026-11-23 17:27:57 BRT to 2026-11-23 17:28:40 BRT (UTC-3)
- Request Volume: 248 automated requests in 43 seconds (all blocked with HTTP 403)
- Activity Type: Automated Credential Harvesting / Secret & Configuration Scanning (.env, .git, GCP/Firebase JSON keys, phpinfo)

Relevant Edge/WAF Logs (excerpt of 13 representative entries out of 248):

```text
datetime_utc | method | host | path | edge_status | client_ip | country
2026-11-23T20:27:58Z | GET | prometheus.agsonhos.com.br | /.git/config | 403 | 34.72.10.200 | US
2026-11-23T20:27:59Z | GET | prometheus.agsonhos.com.br | /.env.local | 403 | 34.72.10.200 | US
2026-11-23T20:27:59Z | POST | prometheus.agsonhos.com.br | / | 403 | 34.72.10.200 | US
2026-11-23T20:28:30Z | GET | prometheus.agsonhos.com.br | /kafka/.env | 403 | 34.72.10.200 | US
2026-11-23T20:28:32Z | GET | prometheus.agsonhos.com.br | /info.php | 403 | 34.72.10.200 | US
2026-11-23T20:28:32Z | GET | prometheus.agsonhos.com.br | /production/.env | 403 | 34.72.10.200 | US
2026-11-23T20:28:35Z | GET | prometheus.agsonhos.com.br | /_profiler/phpinfo | 403 | 34.72.10.200 | US
2026-11-23T20:28:35Z | GET | prometheus.agsonhos.com.br | /server-status.php | 403 | 34.72.10.200 | US
2026-11-23T20:28:38Z | GET | prometheus.agsonhos.com.br | /gcp-credentials.json | 403 | 34.72.10.200 | US
2026-11-23T20:28:38Z | GET | prometheus.agsonhos.com.br | /service-account.json | 403 | 34.72.10.200 | US
2026-11-23T20:28:39Z | GET | prometheus.agsonhos.com.br | /firebase-key.json | 403 | 34.72.10.200 | US
2026-11-23T20:28:39Z | GET | prometheus.agsonhos.com.br | /firebase-adminsdk.json | 403 | 34.72.10.200 | US
2026-11-23T20:28:39Z | GET | prometheus.agsonhos.com.br | /.config/gcloud/application_default_credentials.json | 403 | 34.72.10.200 | US
```

The complete log (all 248 requests in plain text) is attached as `logs-34.72.10.200-2026-11-23.txt`.

Please investigate this activity and take appropriate action in accordance with the Google Cloud Acceptable Use Policy (AUP) to stop this malicious traffic.

Thank you for your time and assistance.

Best regards,
Josias Sobrinho
Developer
