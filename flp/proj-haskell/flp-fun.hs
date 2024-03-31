-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 09.03.2024

import System.Environment (getArgs)

import Src.CART (buildTree)
import Src.StringOps (splitBy, parseTrainingData)
import Src.Type (readTree, classify)


-- Read tree from file, parse it into DTree, read input data from file,
-- and perform inference using the tree.
readAndClassify :: FilePath -> FilePath -> IO ()
readAndClassify treePath dataPath = do
  -- parse tree
  treeData <- readFile treePath
  let tree = fst $ readTree . lines $ treeData

  -- perform inference
  classifyData <- readFile dataPath
  let results = map (classify tree . map read . splitBy ',') (lines classifyData)
  mapM_ putStrLn results

-- Read training data from file and train decision tree on it.
-- The method is inspired by CART algorithm.
trainDecisionTree :: FilePath -> IO () -- (DTree Int Float)
trainDecisionTree trainingDataPath = do
  -- parse training data
  trainingData <- readFile trainingDataPath
  let matrix = parseTrainingData $ lines trainingData
  putStrLn $ show $ buildTree matrix


main :: IO ()
main = do
  args <- getArgs
  case args of
    ["-1", treePath, dataPath] -> readAndClassify treePath dataPath
    ["-2", trainingDataPath] -> trainDecisionTree trainingDataPath
    _ -> error "Invalid arguments!"
