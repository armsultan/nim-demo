```bash
# Download 2048 key
curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam

# Generate 4096 key
openssl dhparam -dsaparam -out dhparam2.pem 4096
```