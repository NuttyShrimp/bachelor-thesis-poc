enum BenchmarkError: Error {
    case UnknownOperation(name: String)
    case LoadFailed(dataName: String)
    case DecoderError(err: Error)
    case RenderError(err: Error)
}
