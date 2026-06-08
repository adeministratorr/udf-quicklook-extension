// The executable's entry point is overridden to _NSExtensionMain via a linker flag
// (see Package.swift), so this file's implicit main() is never executed. It exists
// only to satisfy SwiftPM's requirement that an executable target have an entry file.
