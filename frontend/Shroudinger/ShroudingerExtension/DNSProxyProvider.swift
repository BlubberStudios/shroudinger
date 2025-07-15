import NetworkExtension
import os.log

class DNSProxyProvider: NEDNSProxyProvider {
    
    private let logger = Logger(subsystem: "com.shroudinger.app.extension", category: "DNSProxy")
    
    override func startProxy(options: [String : Any]?, completionHandler: @escaping (Error?) -> Void) {
        logger.info("Starting DNS proxy provider")
        completionHandler(nil)
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.info("Stopping DNS proxy provider")
        completionHandler()
    }
    
    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        logger.debug("Handling new flow")
        
        // Handle UDP flows for DNS queries
        if let udpFlow = flow as? NEAppProxyUDPFlow {
            return handleDNSFlow(udpFlow)
        }
        
        return false
    }
    
    private func handleDNSFlow(_ flow: NEAppProxyUDPFlow) -> Bool {
        logger.debug("Handling DNS flow")
        
        // Read DNS query data
        flow.readDatagrams { [weak self] (datagrams, endpoints, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error reading DNS query: \(error.localizedDescription)")
                return
            }
            
            guard let datagrams = datagrams, let endpoints = endpoints else {
                self.logger.error("No DNS query data received")
                return
            }
            
            for (index, datagram) in datagrams.enumerated() {
                let endpoint = endpoints[index]
                self.processDNSQuery(datagram: datagram, flow: flow, originalEndpoint: endpoint)
            }
        }
        
        return true
    }
    
    
    private func processDNSQuery(datagram: Data, flow: NEAppProxyUDPFlow, originalEndpoint: NWEndpoint) {
        // Check if domain should be blocked
        if shouldBlockDomain(datagram) {
            logger.info("Blocking DNS query")
            // Return NXDOMAIN response
            let response = createBlockedResponse(for: datagram)
            flow.writeDatagrams([response], sentBy: [originalEndpoint]) { error in
                if let error = error {
                    self.logger.error("Error sending blocked response: \(error.localizedDescription)")
                }
            }
        } else {
            // Forward to upstream DNS server
            forwardDNSQuery(datagram, flow: flow, originalEndpoint: originalEndpoint)
        }
    }
    
    private func shouldBlockDomain(_ dnsQuery: Data) -> Bool {
        // TODO: Implement blocklist checking
        // This would check against loaded blocklists
        // For now, return false to allow all queries
        return false
    }
    
    private func createBlockedResponse(for query: Data) -> Data {
        // TODO: Create proper DNS NXDOMAIN response
        // This should return a properly formatted DNS response indicating the domain doesn't exist
        // For now, return empty data
        return Data()
    }
    
    private func forwardDNSQuery(_ query: Data, flow: NEAppProxyUDPFlow, originalEndpoint: NWEndpoint) {
        logger.debug("Forwarding DNS query to upstream server")
        
        // For now, just create a basic DNS response
        // TODO: Implement proper DNS forwarding to encrypted DNS servers (DoT/DoH/DoQ)
        let response = createBasicDNSResponse(for: query)
        
        // Send the response back to the client
        flow.writeDatagrams([response], sentBy: [originalEndpoint]) { error in
            if let error = error {
                self.logger.error("Error sending DNS response: \(error.localizedDescription)")
            }
        }
    }
    
    private func createBasicDNSResponse(for query: Data) -> Data {
        // TODO: Create proper DNS response
        // For now, return a basic response that allows all queries
        // This is a placeholder implementation
        return query // Echo back the query as a temporary solution
    }
}