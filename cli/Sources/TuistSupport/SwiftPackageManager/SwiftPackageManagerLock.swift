import FileSystem
import Foundation
import Path
import TSCBasic
import TuistEnvironment
import TuistLogging

public struct SwiftPackageManagerLock: Sendable {
    private let fileSystem: FileSysteming

    public init(fileSystem: FileSysteming = FileSystem()) {
        self.fileSystem = fileSystem
    }

    public func withLock<T>(
        packagePath: Path.AbsolutePath,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        let lockPath = Environment.current.stateDirectory
            .appending(component: "swift-package-manager-locks")
            .appending(component: "\(packagePath.pathString.md5).lock")

        try await fileSystem.makeDirectory(
            at: lockPath.parentDirectory,
            options: [.createTargetParentDirectories]
        )

        let fileLock = TSCBasic.FileLock(at: try TSCBasic.AbsolutePath(validating: lockPath.pathString))
        Logger.current.debug("Waiting for Swift Package Manager lock at \(lockPath.pathString)")

        return try await fileLock.withLock(type: .exclusive) {
            Logger.current.debug("Acquired Swift Package Manager lock for \(packagePath.pathString)")
            return try await operation()
        }
    }
}
