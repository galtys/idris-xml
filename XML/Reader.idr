-- -------------------------------------------------------------- [ Reader.idr ]
-- Module      : XML.reader
-- Copyright   : (c) Jan de Muijnck-Hughes
-- License     : see LICENSE
-- --------------------------------------------------------------------- [ EOH ]
module XML.Reader

import Lightyear
import Lightyear.Strings

import Effects
import Effect.File
import Effect.Exception

import XML.DOM
import XML.Parser

%access private

public
data XMLError : Type where
  FileParseError : String -> String -> XMLError
  CannotReadFile : String -> XMLError

instance Show XMLError where
  show (FileParseError fn err) =
    unlines [ unwords ["Error parsing file", show fn, "error was"]
            , err]
  show (CannotReadFile fn) = unwords ["Cannot read file:", show fn]


readFile : { [FILE_IO (OpenFile Read)] } Eff String
readFile = readAcc ""
  where
    readAcc : String -> { [FILE_IO (OpenFile Read)] } Eff String
    readAcc acc = if (not !eof)
                     then readAcc (acc ++ !readLine)
                     else pure acc

namespace Doc
  public
  fromString : String -> Either String (Document DOCUMENT)
  fromString str = do
    case parse parseXMLDoc str of
      Left err  => Left $ err
      Right res => pure $ res

  public
  readXMLDoc : String
             -> Eff (Either XMLError (Document DOCUMENT))
                    [FILE_IO ()]
  readXMLDoc f = do
      case !(open f Read) of
        True => do
          src <- readFile
          close
          case Doc.fromString src of
            Left err  => pure $ Left (FileParseError f err)
            Right res => pure $ Right res
        False => pure $ Left (CannotReadFile "Unable to read XML file")

namespace Snippet
  public
  fromString : String -> Either String (Document ELEMENT)
  fromString str = do
    case parse parseXMLSnippet str of
      Left err  => Left $ err
      Right res => pure $ res

  public
  readXMLSnippet : String
                -> Eff (Either XMLError (Document ELEMENT))
                       [FILE_IO ()]
  readXMLSnippet f = do
      case !(open f Read) of
        True => do
          src <- readFile
          close
          case Snippet.fromString src of
            Left err  => pure $ Left (FileParseError f err)
            Right res => pure $ Right res
        False => pure $ Left (CannotReadFile "Unable to read XML file")

-- --------------------------------------------------------------------- [ EOF ]
