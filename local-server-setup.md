# Local Web Server Setup for Godot Game

This guide shows how to set up a local HTTPS server for your Godot web build that can be accessed from other devices on your local network.

## Prerequisites

- Node.js installed on your system
- Godot web build exported to a `web-build` directory
- All devices connected to the same WiFi network

## Steps

### 1. Navigate to your web build directory
```bash
cd /path/to/your/project/web-build
```

### 2. Start the local web server
Use the `local-web-server` package with the following command:

```bash
npx local-web-server --https --cors.origin "*" --cors.credentials --hostname 0.0.0.0 --port 8000
```

**Command breakdown:**
- `--https`: Enables HTTPS (required for many Godot web features)
- `--cors.origin "*"`: Allows cross-origin requests from any domain
- `--cors.credentials`: Enables credentials in CORS requests
- `--hostname 0.0.0.0`: Binds to all network interfaces (makes it accessible from network)
- `--port 8000`: Uses port 8000 (you can change this if needed)

### 3. Run server in background (optional)
If you want the server to run in the background:

```bash
nohup npx local-web-server --https --cors.origin "*" --cors.credentials --hostname 0.0.0.0 --port 8000 > server.log 2>&1 &
```

### 4. Find your local IP address
Get your Mac's IP address on the local network:

```bash
ifconfig en0 | grep "inet " | grep -v 127.0.0.1
```

Example output: `inet 192.168.0.15 netmask 0xffffff00 broadcast 192.168.0.255`

### 5. Verify server is running
Check if the server is listening on port 8000:

```bash
lsof -i :8000
```

## Access URLs

- **Local access (same computer):** `https://localhost:8000` or `https://127.0.0.1:8000`
- **Network access (other devices):** `https://YOUR_IP_ADDRESS:8000`
  - Example: `https://192.168.0.15:8000`

## Troubleshooting for Mobile/Tablet Access

### SSL Certificate Warning
- The browser will show a security warning for the self-signed certificate
- Tap "Advanced" or "More details"
- Select "Proceed to [IP] (unsafe)" or similar option
- This is normal and safe for local development

### Connection Issues
1. **Double-check the IP address** - Make sure you're using the correct IP from step 4
2. **Verify same network** - Ensure all devices are on the same WiFi
3. **Check firewall** - macOS firewall might block incoming connections
4. **Try different port** - If 8000 is blocked, try 8080 or 3000

### Alternative: Simple HTTP Server
If HTTPS causes issues, you can try a simple HTTP server (though some Godot features may not work):

```bash
npx http-server -p 8000 -a 0.0.0.0 --cors
```

## Common Issues and Solutions

### "Unknown option" errors
- The original command with `--cors.embedder.policy` and `--cors.opener.policy` doesn't work
- Use the corrected command from step 2 instead

### Server stops running
- If the server stops, simply re-run the command from step 2
- Use the background version (step 3) to prevent accidental termination

### Port already in use
- Change the port number: `--port 8001` (and update your access URL accordingly)
- Or kill the existing process: `lsof -ti:8000 | xargs kill`

## Notes

- The server needs to be running while you test your game
- Remember to export your Godot project to the web-build directory before testing
- HTTPS is required for many modern web features that Godot games might use