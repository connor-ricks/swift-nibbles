import Foundation

// MARK: - RetryStrategy

/// An ``HTTPRequestRetrier`` that retries qualified requests based on provided HTTP methods, HTTP status codes and `URLError.Codes`
/// Retries are triggered up to the provided number of attempts, and implement an exponential backoff approach with a jitter strategy.
///
/// > Tip: The default values provided for HTTP methods, HTTP status codes and `URLError.Codes` should be a solid starting ground for most
/// netowrking clients. However, you can customize the configuration to tailor this retrier to your needs.
open class RetryStrategy: HTTPRequestRetrier {
    
    // MARK: Constants
    
    public enum Constants {
        
        /// The default number of attempts a request should make to succed before conceding to failure.
        public static let defaultAttempts: Int = 3
        
        /// The default methods for which to consider a retry.
        ///
        /// See [RFC 9110 - Section 9.2.2](https://www.rfc-editor.org/rfc/rfc9110.html#name-idempotent-methods) for more information.
        public static let defaultMethods: Set<HTTPMethod> = [.put, .delete, .get, .head, .options, .trace]
        
        /// The default status codes that should trigger a retry.
        ///
        /// See [RFC 9110 - Section 15](https://www.rfc-editor.org/rfc/rfc9110.html#name-status-codes) for more information.
        public static let defaultStatusCodes: Set<Int> = [408, 500, 502, 503, 504]
        
        /// The default base of the exponential backoff in seconds.
        public static let defaultExponentialBackoffBase: TimeInterval = 2
        
        /// The default jitter strategy for exponential backoff manipulation.
        ///
        /// See ``JitterStrategy`` for more information.
        public static let defaultJitterStrategy: JitterStrategy = .full
        
        /// The default `URLError` codes that should trigger a retry.
        ///
        /// See [URLError.Code](https://developer.apple.com/documentation/foundation/urlerror/code) to learn more.
        public static let defaultUrlErrorCodes: Set<URLError.Code> = [
            // App Transport Security disallowed a connection because there is no secure network connection.
            // [Disabled] - Cannot be changed at runtime.
            // .appTransportSecurityRequiresSecureConnection,
            
            // An app or app extension attempted to connect to a background session that is already connected to a process.
            // [Enabled] - Session could be released during a retry.
            .backgroundSessionInUseByAnotherProcess,
            
            // The shared container identifier of the URL session configuration is needed but has not been set.
            // [Disabled] - Cannot be changed at runtime.
            //.backgroundSessionRequiresSharedContainer,
            
            // The app is suspended or exits while a background data task is processing.
            // [Enabled] - App could return to the foreground or relaunch during a retry.
            .backgroundSessionWasDisconnected,
            
            // The URL Loading system received bad data from the server.
            // [Enabled] - The server could return valid data during a retry.
            .badServerResponse,
            
            // A malformed URL prevented a URL request from being initiated.
            // [Disabled] - Retrying a request with the a bad URL will likely still be bad.
            //.badURL,
            
            // A connection was attempted while a phone call is active on a network that does not support
            // simultaneous phone and data communication (EDGE or GPRS).
            // [Enabled] - The phone call could end during a retry.
            .callIsActive,
            
            // An asynchronous load has been canceled.
            // [Disabled] - The request was explicitly cancelled.
            //.cancelled,
            
            // A download task couldn’t close the downloaded file on disk.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.cannotCloseFile,
            
            // An attempt to connect to a host failed.
            // [Enabled] - Connection could succeed during a retry.
            .cannotConnectToHost,
            
            // A download task couldn’t create the downloaded file on disk because of an I/O failure.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.cannotCreateFile,
            
            // Content data received during a connection request had an unknown content encoding.
            // [Disabled] - Unlikely to receive a different encoding of data by retrying.
            //.cannotDecodeContentData,
            
            // Content data received during a connection request could not be decoded for a known content encoding.
            // [Disabled] - Unlikely to receive a different encoding of data by retrying.
            //.cannotDecodeRawData,
            
            // The host name for a URL could not be resolved.
            // [Enabled] - The host could be resolved during a retry.
            .cannotFindHost,
            
            // A request to load an item only from the cache could not be satisfied.
            // [Enabled] - Cache could be updated during a retry.
            .cannotLoadFromNetwork,
            
            // A download task was unable to move a downloaded file on disk.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.cannotMoveFile,
            
            // A download task was unable to open the downloaded file on disk.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.cannotOpenFile,
            
            // A task could not parse a response.
            // [Disabled] - Unlikely to receive a different response by retrying.
            //.cannotParseResponse,
            
            // A download task was unable to remove a downloaded file from disk.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.cannotRemoveFile,
            
            // A download task was unable to write to the downloaded file on disk.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.cannotWriteToFile,
            
            // A client certificate was rejected.
            // [Disabled] - Unlikely to change during a retry.
            //.clientCertificateRejected,
            
            // A client certificate was required to authenticate an SSL connection during a request.
            // [Disabled] - Unlikely to change during a retry.
            //.clientCertificateRequired,
            
            // The length of the resource data exceeds the maximum allowed.
            // [Disabled] - Unlikely to change during a retry.
            //.dataLengthExceedsMaximum,
            
            // The cellular network disallowed a connection.
            // [Enabled] - Could connect to Wifi during a retry.
            .dataNotAllowed,
            
            // The host address could not be found via DNS lookup.
            // [Enabled] DNS lookup could succed during a retry.
            .dnsLookupFailed,
            
            // A download task failed to decode an encoded file during the download.
            // [Enabled] The stream encoding could change during a retry.
            .downloadDecodingFailedMidStream,
            
            // A download task failed to decode an encoded file after downloading.
            // [Enabled] The stream encoding could change during a retry.
            .downloadDecodingFailedToComplete,
            
            // A file does not exist.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.fileDoesNotExist,
            
            // A request for an FTP file resulted in the server responding that the file is not a plain file, but a directory.
            // [Disabled] - Unlikely to recover from a FileSystem error.
            //.fileIsDirectory,
            
            // A redirect loop has been detected or the threshold for number of allowable redirects has been exceeded (currently 16).
            // [Disabled] - Unlikely to change during a retry.
            //.httpTooManyRedirects,
            
            // The attempted connection required activating a data context while roaming, but international roaming is disabled.
            // [Enabled] - Could connect to Wifi during a retry.
            .internationalRoamingOff,
            
            // A client or server connection was severed in the middle of an in-progress load.
            // [Enabled] - Could connect during a retry.
            .networkConnectionLost,
            
            // A resource couldn’t be read because of insufficient permissions.
            // [Disabled] - Unlikely to change during a retry.
            //.noPermissionsToReadFile,
            
            // A network resource was requested, but an internet connection has not been established and cannot be established automatically.
            // [Enabled] - Could connect during a retry.
            .notConnectedToInternet,
            
            // A redirect was specified by way of server response code, but the server did not accompany this code with a redirect URL.
            // [Disabled] - Unlikely to change during a retry.
            //.redirectToNonExistentLocation,
            
            // A body stream is needed but the client did not provide one.
            // [Disabled] - Unlikely to change during a retry.
            //.requestBodyStreamExhausted,
            
            // A requested resource couldn’t be retrieved.
            // [Disabled] - Unlikely to change during a retry.
            //.resourceUnavailable,
            
            // An attempt to establish a secure connection failed for reasons that can’t be expressed more specifically.
            // [Enabled] - Could connect during a retry.
            .secureConnectionFailed,
            
            // A server certificate had a date which indicates it has expired, or is not yet valid.
            // [Disabled] - Unlikely to change during a retry.
            //.serverCertificateHasBadDate,
            
            // A server certificate was not signed by any root server.
            // [Disabled] - Unlikely to change during a retry.
            //.serverCertificateHasUnknownRoot,
            
            // A server certificate is not yet valid.
            // [Disabled] - Unlikely to change during a retry.
            //.serverCertificateNotYetValid,
            
            // A server certificate is not yet valid.
            // [Disabled] - Unlikely to change during a retry.
            //.serverCertificateUntrusted,
            
            // An asynchronous operation timed out.
            // [Enabled] - Could succeed during a retry.
            .timedOut,
            
            // The URL Loading System encountered an error that it can’t interpret.
            // [Disabled] - Unlikely to change during a retry.
            .unknown,
            
            // A properly formed URL couldn’t be handled by the framework.
            // [Disabled] - Unlikely to change during a retry.
            .unsupportedURL,
            
            // Authentication is required to access a resource.
            // [Disabled] - Unlikely to change during a retry.
            .userAuthenticationRequired,
            
            // An asynchronous request for authentication has been canceled by the user.
            // [Disabled] - Unlikely to change during a retry.
            .userCancelledAuthentication,
            
            // A server reported that a URL has a non-zero content length, but terminated the network connection gracefully without sending any data.
            // [Disabled] - Unlikely to change during a retry.
            .zeroByteResource,
        ]
    }
    
    // MARK: JitterStrategy
    
    /// Defines a strategy for backoff jitter.
    ///
    /// Given a multitude of clients interacting with a service at the same time, simply backing off does not solve the problem of dispersing a service's load over time,
    /// it merely delays it. By adding jitter, we are able to better distribute the load over time, providing less contention for resources by competing clients.
    ///
    /// [Learn more about Exponential Backoff And Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
    public enum JitterStrategy {
        /// A strategy that introduces no jitter into the backoff delay.
        ///
        /// Before Jitter: 5
        /// After No Jitter: 5
        case none
        
        /// A strategy that introduces randomness between half and full backoff delays.
        ///
        /// Before Jitter: `5`
        /// After Equal Jitter: `Double.random(2.5...5)`
        case equal
        
        /// A strategy that introduces full randomness between zero and the backoff delay.
        ///
        /// Before Jitter: `5`
        /// After Full Jitter: `Double.random(0...5)`
        case full
        
        /// Creates a new delay from the provided delay using the ``JitterStrategy``.
        func jitter(for delay: TimeInterval) -> TimeInterval {
            switch self {
            case .none:
                return delay
            case .equal:
                let half = delay / 2
                return half + .random(in: 0...half)
            case .full:
                return TimeInterval.random(in: 0...delay)
            }
        }
    }
    
    // MARK: Properties
    
    /// The total number of times a request should be allowed to retry.
    public let attempts: Int
    
    /// The methods for which to consider a retry.
    public let methods: Set<HTTPMethod>
    
    /// The `URLError.Codes` that should trigger a retry.
    public let urlErrorCodes: Set<URLError.Code>
    
    /// The status codes that should trigger a retry.
    public let statusCodes: Set<Int>
    
    /// The base of the exponential backoff in seconds.
    ///
    /// This number is the basis from which the backoff is calculated. That is, for each
    /// retried attempt, the delay will scale this value exponentially.
    public let exponentialBackoffBase: TimeInterval
    
    /// The jitter strategy to apply to the total delay duration.
    public let jitterStrategy: JitterStrategy
    
    // MARK: Initializers
    
    public init(
        attempts: Int = Constants.defaultAttempts,
        methods: Set<HTTPMethod> = Constants.defaultMethods,
        urlErrorCodes: Set<URLError.Code> = Constants.defaultUrlErrorCodes,
        statusCodes: Set<Int> = Constants.defaultStatusCodes,
        exponentialBackoffBase: TimeInterval = Constants.defaultExponentialBackoffBase,
        jitterStrategy: JitterStrategy = Constants.defaultJitterStrategy
    ) {
        self.attempts = attempts
        self.methods = methods
        self.urlErrorCodes = urlErrorCodes
        self.statusCodes = statusCodes
        self.exponentialBackoffBase = exponentialBackoffBase
        self.jitterStrategy = jitterStrategy
    }
    
    // MARK: HTTPRequestRetrier
    
    public func retry(
        _ request: URLRequest,
        for session: URLSession,
        with response: HTTPURLResponse?,
        dueTo error: Error,
        previousAttempts: Int
    ) async throws -> RetryDecision {
        if shouldRetry(request, for: session, with: response, dueTo: error, previousAttempts: previousAttempts) {
            let base = Double(2)
            let exponent = max(0, Double(previousAttempts - 1))
            let delay = exponentialBackoffBase * pow(base, exponent)
            return .retryAfterDelay(.seconds(jitterStrategy.jitter(for: delay)))
        } else {
            return .concede
        }
    }
    
    // MARK: Helpers
    
    /// Whether or not the request should be retried given the current state of the retrier.
    open func shouldRetry(
        _ request: URLRequest,
        for session: URLSession,
        with response: HTTPURLResponse?,
        dueTo error: Error,
        previousAttempts: Int
    ) -> Bool {
        guard
            previousAttempts < attempts,
            let method = request.httpMethod.flatMap({ HTTPMethod(rawValue: $0) }),
            methods.contains(method)
        else {
            return false
        }
        
        if let response, statusCodes.contains(response.statusCode) {
            return true
        } else if let error = error as? URLError, urlErrorCodes.contains(error.code) {
            return true
        } else {
            return false
        }
    }
}

// MARK: - HTTPRequest + RetryStrategy

extension HTTPRequest {
    /// Applies a ``RetryStrategy`` with the provided configuration.
    @discardableResult
    public func retryStrategy(
        attempts: Int = RetryStrategy.Constants.defaultAttempts,
        methods: Set<HTTPMethod> = RetryStrategy.Constants.defaultMethods,
        urlErrorCodes: Set<URLError.Code> = RetryStrategy.Constants.defaultUrlErrorCodes,
        statusCodes: Set<Int> = RetryStrategy.Constants.defaultStatusCodes,
        exponentialBackoffBase: TimeInterval = RetryStrategy.Constants.defaultExponentialBackoffBase,
        jitterStrategy: RetryStrategy.JitterStrategy = RetryStrategy.Constants.defaultJitterStrategy
    ) -> Self {
        retry(with: RetryStrategy(
            attempts: attempts,
            methods: methods,
            urlErrorCodes: urlErrorCodes,
            statusCodes: statusCodes,
            exponentialBackoffBase: exponentialBackoffBase,
            jitterStrategy: jitterStrategy
        ))
    }
}
