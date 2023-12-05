# ZoiaBinReader

Reads Zoia saved '.bin' files.

Coming soon: test harness example.

Download the package and create some code that will read your Zoia .bin

```
func load(path: String = "011_zoia_Crunch_Time", subdirectory: String? = nil) async throws {
        do {
            let url = Bundle.main.url(forResource: path, withExtension: "bin", subdirectory: subdirectory)
            let reader = try ZoiaFileReader(fileURL: url!)
            file = try await reader.read()
        } catch {
            throw error
        }
    }
```

```
try await zoiaModel.load(path: "000_zoia_slightlyrandom", subdirectory: "Factory Euroburo")
```
