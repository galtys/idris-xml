-- --------------------------------------------------------------- [ Types.idr ]
-- Module      : Types
-- Copyright   : (c) Jan de Muijnck-Hughes
-- License     : see LICENSE
--
-- Types representing XML documents,
-- --------------------------------------------------------------------- [ EOH ]
module XML.Types

-- ------------------------------------------------------------------ [ QNames ]

data QName : Type where
  MkQName : (name : String)
          -> (nspace : Maybe String)
          -> (nprefix : Maybe String)
          -> QName

MkSQName : String -> QName
MkSQName n = MkQName n Nothing Nothing

instance Show QName where
  show (MkQName n ns pre) = unwords ["[", showPre, n, showNS, "]\n"]
    where
      showPre = case pre of
        Just p => p ++ ":"
        Nothing => ""
      showNS = case ns of
        Just n => case pre of
          Just p => unwords ["xmlns:",p,"=",n]
          Nothing => unwords ["xmlns=",n]
        Nothing => ""

instance Eq QName where
  (==) (MkQName x xs _) (MkQName y ys _) = x == y && xs == ys

-- ------------------------------------------------------------ [ Instructions ]
-- <?target data?>
data Instruction : Type where
  MkInstruction : (iTarget : String)
                -> (iData : String)
                -> Instruction

instance Show Instruction where
  show (MkInstruction t d) = unwords ["[?", t , d,"?]\n"]

instance Eq Instruction where
  (==) (MkInstruction x xs) (MkInstruction y ys) = x == y && xs == ys

mutual
  data Element : Type where
    MkElement : (name : QName)
              -> (attrs : List (QName, String))
              -> (nodes : List Node)
              -> Element

  instance Show Element where
    show (MkElement n as ns) = unwords ["[",show n, show as, show ns,"]\n"]

  %assert_total
  eqElement : Element -> Element -> Bool
  eqElement (MkElement x xs xxs) (MkElement y ys yys) = x == y && xs == ys && xxs == yys

  instance Eq Element where
    (==) x y = eqElement x y

  data Node : Type where
    NodeElement : Element -> Node
    NodeInstruction : Instruction -> Node
    NodeContent : String -> Node
    NodeComment : String -> Node

  instance Show Node where
    show (NodeElement e)     = show e
    show (NodeInstruction i) = show i
    show (NodeContent c)     = unwords ["[Text", show c, "]\n"]
    show (NodeComment txt)   = unwords ["[Comment", show txt, "]\n"]

  instance Eq Node where
    (==) (NodeElement x)     (NodeElement y)     = x == y
    (==) (NodeInstruction x) (NodeInstruction y) = x == y
    (==) (NodeContent x)     (NodeContent y)     = x == y
    (==) (NodeComment x)     (NodeContent y)     = x == y
    (==) _                   _                   = False


-- --------------------------------------------------------------- [ Doc Types ]

data ExternalID : Type where
  SystemID : String -> ExternalID
  PublicID : String -> String -> ExternalID

instance Show ExternalID where
  show (SystemID loc)       = unwords ["SYSTEM", show loc]
  show (PublicID ident loc) = unwords ["PUBLIC", show ident, show loc]

instance Eq ExternalID where
  (==) (SystemID x)      (SystemID y)      = x == y
  (==) (PublicID x xloc) (PublicID y yloc) = x == y && xloc == yloc
  (==) _                 _                 = False

data DocType : Type where
  MkDocType : (name : String)
          -> (ident : Maybe ExternalID)
          -> DocType

instance Show DocType where
  show (MkDocType n ident) = unwords ["[!DOCTYPE", n, show ident, "]\n"]

instance Eq DocType where
  (==) (MkDocType x xid) (MkDocType y yid) = x == y && xid == yid

-- --------------------------------------------------------------- [ Documents ]
data Misc : Type where
  MiscInstruction : Instruction -> Misc
  MiscComment     : String -> Misc

instance Show Misc where
  show (MiscInstruction i) = show i
  show (MiscComment     x) = unwords ["[Comment", show x, "]"]

instance Eq Misc where
  (==) (MiscInstruction x) (MiscInstruction y) = x == y
  (==) (MiscComment x)     (MiscComment y)     = x == y
  (==) _                   _                   = False

data Prologue : Type where
  MkPrologue : (before : List Misc)
             -> (dtype : Maybe DocType)
             -> (after : List Misc)
             -> Prologue

instance Show Prologue where
  show (MkPrologue b dtd a) = unwords [show b,"\n", show dtd, "\n", show a,"\n"]

instance Eq Prologue where
  (==) (MkPrologue xb xd xa) (MkPrologue yb yd ya) = xb == yb && xd == yd && xa == ya


-- ---------------------------------------------------------------- [ Document ]
data Document : Type where
  MkDoc : (prologue : Prologue)
        -> (root : Element)
        -> (epilogue : List Misc)
        -> Document

MkPureDocument : Element -> Document
MkPureDocument r = MkDoc (MkPrologue [] Nothing []) r []

instance Show Document where
  show (MkDoc p r e) = unwords [show p,"\n", show r, "\n", show e,"\n"]

instance Eq Document where
  (==) (MkDoc a b c) (MkDoc x y z) = a == x && b == y && c == z
-- --------------------------------------------------------------------- [ EOF ]
