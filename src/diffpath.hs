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
        status <- Files.getSymbolicLinkStatus path
        if Files.isRegularFile status || Files.isSymbolicLink status
            then do
            let mode = Files.fileMode status
            return $ (mode `Files.intersectFileModes` executeModes /= Files.nullFileMode)
        else return False
    where
        executeModes = Files.ownerExecuteMode `Files.unionFileModes` Files.groupExecuteMode `Files.unionFileModes` Files.otherExecuteMode

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
formatItem set x = if x `Set.member` set then x else '\t' : x

main :: IO ()
main = do
    args <- getArgs
    case args of
        [path1, path2] -> do
            execs1 <- getAllExecutables path1
            execs2 <- getAllExecutables path2
            let diff = symmetricDifference execs1 execs2
            Set.foldr (\x acc -> putStrLn (formatItem execs1 x) >> acc) (return ()) diff
        _ -> do
            progName <- getProgName
            putStrLn $ "Usage: " ++ progName ++ " PATH1 PATH2"
