-- FLP: Functional Project: Decision Trees
-- Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
-- Date: 09.03.2024

module Src.StringOps
  (
    strip
  , startsWith
  , split
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
split :: String -> Char -> [String]
split "" _ = []
split str delimiter =
  let (token, rest) = span (/= delimiter) str
  in token : split ( dropWhile (== delimiter) rest ) delimiter
