import Foundation
import ZIPFoundation

actor ArchiveActor {
    let archive: Archive

    init(url: URL, accessMode: Archive.AccessMode) throws {
        archive = try Archive(url: url, accessMode: accessMode)
    }

    func addInvoicePdf(orderId: Int, invoice: Data) throws {
        try archive.addEntry(
            with: "invoice_\(orderId).pdf", type: .file,
            uncompressedSize: Int64(invoice.count),
            // bufferSize: 4,
            provider: { (position, size) -> Data in
                return invoice.subdata(in: Data.Index(position)..<Int(position) + size)
            })
    }
}
