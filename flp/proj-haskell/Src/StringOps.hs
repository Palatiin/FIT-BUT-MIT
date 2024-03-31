-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 09.03.2024

module Src.StringOps
  (
    strip
  , startsWith
  , splitBy
  , parseTrainingData
  ) where

import Data.Char (isSpace)


-- remove whitespaces from both ends of string
strip :: String -> String
strip = str . str
  where str = reverse . dropWhile isSpace

-- check String's prefix
startsWith :: Eq c => [c] -> [c] -> Bool
startsWith _ [] = True
startsWith [] _ = False
startsWith (x : xs) (y : ys) = x == y && startsWith xs ys

-- split String by Char delimiter
splitBy :: Char -> String -> [String]
splitBy _ "" = []
splitBy delimiter str =
  let (token, rest) = span (/= delimiter) str
  in token : splitBy delimiter ( dropWhile (== delimiter) rest )

-- parse columns of training data - the last column is string
parseColumns :: [String] -> [Either Float String]
parseColumns [] = []
parseColumns [x] = [Right x]
parseColumns (x : xs) = Left (read x) : parseColumns xs

-- parse training data into matrix
parseTrainingData :: [String] -> [[Either Float String]]
parseTrainingData [] = []
parseTrainingData (line : rest) = parseColumns (splitBy ',' line) : parseTrainingData rest
