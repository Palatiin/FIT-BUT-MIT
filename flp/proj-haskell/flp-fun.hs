-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 09.03.2024

import System.Environment (getArgs)

import Src.StringOps (splitBy)
import Src.Type (readTree, classify)


readAndClassify :: FilePath -> FilePath -> IO ()
readAndClassify treePath dataPath = do
  treeData <- readFile treePath
  let tree = fst $ readTree . lines $ treeData
--  putStrLn $ show tree

  classifyData <- readFile dataPath
  let results = map (classify tree . map read . splitBy ',') (lines classifyData)
  mapM_ putStrLn results

trainDecisionTree :: FilePath -> IO () -- (DTree Int Float)
trainDecisionTree trainingDataPath = do
  trainingData <- readFile trainingDataPath
  putStrLn trainingData


main :: IO ()
main = do
  args <- getArgs
  case args of
    ["-1", treePath, dataPath] -> readAndClassify treePath dataPath
    ["-2", trainingDataPath] -> trainDecisionTree trainingDataPath
    _ -> error "Invalid arguments!"
