STATIC Snd_DMA := 0, ;
       IsSound := .F.

#include "commands.ch"

FUNCTION InitSnd(nBase)

      IF !InitSound( nBase )
	 alert("Greska u inicijalizaciji zvucne kartice!", {" OK "})
	 RETURN NIL
      ENDIF

      Snd_DMA = nBase
      IsSound = .T.

RETURN NIL

FUNCTION PlaySound( opc )

LOCAL DmaChannel := {;
		       {135, 0, 1},;
		       {131, 2, 3},;
		       {129, 2, 3},;
		       {130, 6, 7} }

LOCAL cPod     := Replicate( Chr(0), 6 ), ;
      nHandle  := 0

LOCAL nSegSamp := 0, ;
      nOffSamp := 0, ;
      nOffset  := 0, ;
      nPage    := 0, ;
      nDMA     := 1

      DEFAULT opc TO .F.

      IF !IsSound
	 RETURN NIL
      ENDIF

      InitSound( 2 )

      nSize = I2U( GetSize() )

      nSegSamp = I2U( GetSEG() )
      nOffSamp = I2U( GetOFF() ) + 2

      SpkON()
      nOffset = x_shl( nSegSamp, 4 ) + nOffSamp
      nPage   = x_shr( nSegSamp + x_shr( nOffSamp, 4 ), 12 )

      ToPort( 10, 4 + nDMA )
      ToPort( 12, 0 )
      ToPort( 11, 72 + nDMA )
      ToPort( DMAChannel[Snd_DMA,2], GetLo( nOffset ) )
      ToPort( DMAChannel[Snd_DMA,2], GetHi( nOffset ) )
      ToPort( DMAChannel[Snd_DMA,1], nPage )
      ToPort( DMAChannel[Snd_DMA,3], GetLo( nSize ) )
      ToPort( DMAChannel[Snd_DMA,3], GetHi( nSize ) )
      ToPort( 10, nDMA )

      WriteDSP( 64 )
      WriteDSP( 165 )
/*
      WriteDSP( 65 )
      WriteDSP( 256 - Int( 1000000 / nFreq ) )
*/
      WriteDSP( 20 )
      WriteDSP( GetLo( nSize ) )
      WriteDSP( GetHi( nSize ) )

      IF opc
	 DO WHILE FromPort(3) != -1
	 ENDDO
      ENDIF

RETURN NIL

FUNCTION LoadSound( cFile )

LOCAL nHandle := 0, ;
      nSize   := 0, ;
      lRet    := .T.

      IF !File( cFile )
	 RETURN .F.
      ENDIF

      nSize = FileSize( cFile )
      nSize = iif( nSize > 32766, 32766, nSize )

      nHandle = FOpen( cFile )

      LoadSamp( nHandle, nSize )

      FClose( nHandle )

RETURN lRet

FUNCTION SpkON()

      WriteDSP( 209 )

RETURN NIL

FUNCTION SpkOFF()

      WriteDSP( 211 )

RETURN NIL

STATIC FUNCTION DMAStop()

      WriteDSP( 208 )

RETURN NIL

STATIC FUNCTION DMACont()

      WriteDSP( 212 )

RETURN NIL

FUNCTION I2U( nInt )

LOCAL uRet := 0

      uRet = Bin2W( I2Bin( nInt ) )

RETURN uRet

FUNCTION SetVolume( nVolume )

      if nVolume > 255
	 nVolume := 255
      endif

      WriteMixer(48, nVolume)
      WriteMixer(49, nVolume)
      WriteMixer(50, nVolume)
      WriteMixer(51, nVolume)

RETURN NIL
