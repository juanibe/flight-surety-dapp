// import http from "http";
const http = require("http");
// import app from "./server";
const app = require("./server");

const server = http.createServer(app);

let currentApp = app;

server.listen(3000);

console.log("Server listening on port", 3000);

if (module.hot) {
  module.hot.accept("./server", () => {
    server.removeListener("request", currentApp);
    server.on("request", app);
    currentApp = app;
  });
}
