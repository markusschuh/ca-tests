import java.io.*;
import javax.net.ssl.SSLServerSocketFactory;
import javax.net.ssl.SSLServerSocket;
import javax.net.ServerSocketFactory;
import java.net.Socket;

public class SSLSocketServer {
  public static void main(String[] args) throws IOException {
    if (args.length < 1 || args.length > 2) {
      System.out.println("Usage: "+SSLSocketServer.class.getName()+" <port> [ clientauth ]");
      System.exit(1);
    }
    int port = Integer.parseInt(args[0]);
    boolean clientauth = false;
    if (args.length == 2) {
      clientauth = true;
    }
    ServerSocketFactory serversocketfactory = SSLServerSocketFactory.getDefault();
    System.out.println("listening for messages...");
    try (SSLServerSocket listener = (SSLServerSocket) serversocketfactory.createServerSocket(port)) {
      listener.setEnabledCipherSuites(new String[] { "TLS_AES_128_GCM_SHA256" });
      listener.setEnabledProtocols(new String[] { "TLSv1.3" });
      listener.setNeedClientAuth(clientauth);
      System.out.println("Need client certificate: " + clientauth);
      try (Socket socket = listener.accept()) {
        InputStream is = new BufferedInputStream(socket.getInputStream());
        byte[] data = new byte[2048];
        int len = is.read(data);
        String message = new String(data, 0, len);
        OutputStream os = new BufferedOutputStream(socket.getOutputStream());
        System.out.printf("server received %d bytes: '%s'%n", len, message);
        String response = "Message '" + message + "' processed by server.";
        os.write(response.getBytes(), 0, response.getBytes().length);
        os.flush();
        socket.close();
      }
    }
  }
}
