-- --------------------------------------------------------------- [ XPath.idr ]
-- Module    : XPath.idr
-- Copyright : (c) Jan de Muijnck-Hughes
-- License   : see LICENSE
-- --------------------------------------------------------------------- [ EOH ]
module XML.XPath

import XML.DOM

import public XML.XPath.Types
import XML.XPath.Parser

%access private

-- ------------------------------------------------------------------- [ ERROR ]

public export
data XPathError : Type where
  MalformedQuery : (qstr : String) -> (msg : String) -> XPathError
  QueryError     : (qstr : XPath a) -> (loc : XMLElem) -> (msg : Maybe String) -> XPathError
  SingletonError : String -> XPathError
  GenericError   : String -> XPathError

public export
Show XPathError where
  show (MalformedQuery q err) = unwords
    [ "Query:"
    , show q
    , "is malformed because"
    , err]

  show (QueryError qstr loc msg) = unlines
    [ unwords ["QueryError:", fromMaybe "" msg]
    , "Asking for:"
    , unwords ["\t", show qstr]
    , "in"
    , unwords ["\t", (getTagName loc)]]
  show (GenericError msg) = unwords ["Generic Error:", msg]
  show (SingletonError m) = unwords ["At Least one node expected.", show m]

-- ------------------------------------------------------------------- [ Query ]

private
evaluatePath : XPath a -> Document ELEMENT -> List XMLNode

evaluatePath (Query q) n = evaluatePath q n
evaluatePath (Elem e)  n = mkNodeList $ (getChildElementsByName e n)
evaluatePath (Any)     n = mkNodeList $ getChildElements n

evaluatePath (Attr a)  n =
    case getAttribute a n of
      Just v  => [mkTextNode v]
      Nothing => Nil

evaluatePath (CData)   n = mkNodeList (getCData $ getNodes n)
evaluatePath (Text)    n = mkNodeList (getText $ getNodes n)
evaluatePath (Comment) n = mkNodeList (getComments $ getNodes n)
evaluatePath (Root r)  n with (r)
    | Any    = [Node n]
    | Elem e = if getTagName n == e then [Node n] else Nil
evaluatePath (DRoot r) n with (r)
    | Any    = mkNodeList $ getAllChildren n
    | Elem e = mkNodeList $ getElementsByName e n
evaluatePath (p </> c) n = concatMap (evaluatePath c) $ getElements (evaluatePath p n)
evaluatePath (p <//> child) n with (child)
    | Any    = mkNodeList $ concatMap (getAllChildren) $ getElements (evaluatePath p n)
    | Elem c = mkNodeList $ concatMap (getElementsByName c) $ getElements (evaluatePath p n)
    | path   = concatMap (evaluatePath path) $ getElements (evaluatePath p n)

-- ------------------------------------------------------------------ [ Parser ]

private
doQuery : String
       -> Document ELEMENT
       -> Either XPathError (List $ Document NODE)
doQuery qstr e =
  case parse parseQuery qstr of
    Left err => Left  $ MalformedQuery qstr err
    Right q  => Right $ evaluatePath q e

public export
data CanQuery : NodeTy -> Type where
  CQDoc  : CanQuery DOCUMENT
  CQElem : CanQuery ELEMENT

export
query : String
     -> Document ty
     -> {auto prf : CanQuery ty}
     -> Either XPathError (List $ Document NODE)
query {ty=ELEMENT}  qstr n                      = doQuery qstr n
query {ty=DOCUMENT} qstr (MkDocument _ _ _ _ e) = doQuery qstr e

-- --------------------------------------------------------------------- [ EOF ]
