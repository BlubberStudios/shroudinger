import NetworkExtension

@main
class ShroudingerExtension {
    static func main() {
        // This is the entry point for the DNS proxy extension
        // The actual work is done in DNSProxyProvider
        NEProvider.startSystemExtensionMode()
    }
}