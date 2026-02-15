import AsyncHTTPClient

enum WorkerError: Error {
    case AlreadyBusy
    case InvalidOperation(String, String?)
    case RequestError(Error)
    case FailedHTTPRequest(HTTPClientResponse)
}

enum GenericError: Error {
    case RuntimeError(String)
}
