const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('/tmp/key.pem'),
  cert: fs.readFileSync('/tmp/cert.pem')
};

https.createServer(options, function (req, res) {
  res.writeHead(200);
  res.end("hello world from nodejs server\n");
}).listen(8443);