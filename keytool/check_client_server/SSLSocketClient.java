import java.io.*;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.SSLSocket;
public class SSLScocketClient {
  public static void main(String[] args) {
    String message = "Hello world";
    if (args.length != 2) {
      System.out.println("Usage: "+SSLScocketClient.class.getName()+" <host> <port>");
      System.exit(1);
    }
    String host = args[0];
    int    port = Integer.parseInt(args[1]);
    SSLSocketFactory sslsocketfactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
    System.out.println("sending message: '" + message + "'");
    try {
      SSLSocket sslsocket = (SSLSocket) sslsocketfactory.createSocket(host, port);
      sslsocket.setEnabledCipherSuites(new String[] { "TLS_AES_128_GCM_SHA256" });
      sslsocket.setEnabledProtocols(new String[] { "TLSv1.3" });
      OutputStream os = new BufferedOutputStream(sslsocket.getOutputStream());
      os.write(message.getBytes());
      os.flush();
      InputStream is = new BufferedInputStream(sslsocket.getInputStream());
      byte[] data = new byte[2048];
      int len = is.read(data);
      System.out.printf("client received %d bytes: %s%n", len, new String(data, 0, len));
    } catch (Exception exception) {
      exception.printStackTrace();
    }
  }
}
