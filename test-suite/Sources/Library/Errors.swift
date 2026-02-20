import AsyncHTTPClient

public enum WorkerError: Error {
    case AlreadyBusy
    case InvalidOperation(String, String?)
    case RequestError(Error)
    case FailedHTTPRequest(HTTPClientResponse)
}

public enum GenericError: Error {
    case RuntimeError(String)
}
