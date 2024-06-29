import           Control.Monad      (foldM)
import           Data.Set           (Set)
import qualified Data.Set           as Set
import           System.Directory   (doesFileExist, listDirectory)
import           System.Environment (getArgs, getProgName)
import           System.FilePath    ((</>))
import qualified System.Posix.Files as Files

-- Function to split a string by a delimiter
split :: Char -> String -> [String]
split _ "" = []
split delim s =
    let (part, rest) = break (== delim) s
    in part : case rest of
                []     -> []
                (_:rs) -> split delim rs

-- Function to check if a file is executable by any user
isExecutable :: FilePath -> IO Bool
isExecutable path = do
    exists <- doesFileExist path
    if exists
        then do
            status <- Files.getFileStatus path
            let mode = Files.fileMode status
            return $ (mode `Files.intersectFileModes` executeModes /= Files.nullFileMode)
        else return False

-- Get all executable files in a directory
getExecutables :: FilePath -> IO (Set String)
getExecutables dir = do
    allFiles <- listDirectory dir
    foldM addIfExecutable Set.empty allFiles
  where
    addIfExecutable set file = do
      isExec <- isExecutable (dir </> file)
      return $ if isExec
               then Set.insert file set
               else set

executeModes = Files.ownerExecuteMode `Files.unionFileModes` Files.groupExecuteMode `Files.unionFileModes` Files.otherExecuteMode

-- Get all executables from a PATH
getAllExecutables :: String -> IO (Set String)
getAllExecutables path = do
    let dirs = split ':' path
    foldl Set.union Set.empty <$> mapM getExecutables dirs

-- Compute the diff and format the output
symmetricDifference :: Set String -> Set String -> Set String
symmetricDifference execs1 execs2 = (execs1 `Set.difference` execs2) `Set.union` (execs2 `Set.difference` execs1)

-- Format a single item for output
formatItem :: Set String -> String -> String
formatItem execs1 x = if x `Set.member` execs1 then x else '\t' : x

main :: IO ()
main = do
    progName <- getProgName
    args <- getArgs
    case args of
        [path1, path2] -> do
            execs1 <- getAllExecutables path1
            execs2 <- getAllExecutables path2
            let diff = symmetricDifference execs1 execs2
            Set.foldr (\x acc -> putStrLn (formatItem execs1 x) >> acc) (return ()) diff
        _ -> putStrLn $ "Usage: " ++ progName ++ " PATH1 PATH2"