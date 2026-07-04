# PantherLang Web Runtime Fix 1

This patch makes the web/API examples use real `web {}` and `api {}` route blocks so `--serve` starts an actual HTTP server.

## Apply

```bash
unzip -o pantherlang_web_runtime_fix1_real_serve.zip
chmod +x bootstrap_web_runtime_fix1_real_serve.sh
./bootstrap_web_runtime_fix1_real_serve.sh
```

## Manual test

Terminal 1:

```bash
panther run examples/hello_web/main.pan --serve
```

Terminal 2:

```bash
curl http://localhost:8080
curl http://localhost:8080/health
```
