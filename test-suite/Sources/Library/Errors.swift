enum WorkerError: Error {
    case AlreadyBusy
    case RequestError(Error)
}
