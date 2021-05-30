IF (select count(*) from sysobjects where name like 'CD_FONDOS_CodTpRecepcionMon_1') <> 0
    ALTER TABLE FONDOSREAL
        DROP CD_FONDOS_CodTpRecepcionMon_1
go

IF (select count(*) from sysobjects where name like 'CD_FONDOSREAL_CodTpRecepcionMon_1') = 0
    ALTER TABLE FONDOSREAL
        ADD CONSTRAINT 	CD_FONDOSREAL_CodTpRecepcionMon_1 DEFAULT 'VP' FOR CodTpRecepcionMon

GO
----v4.3.1
IF (select count(*) from sysobjects where name like 'CD_FONDOS_CodTpCotizacionRecepMon_1') <> 0
    ALTER TABLE FONDOSREAL
        DROP CD_FONDOS_CodTpCotizacionRecepMon_1

GO

IF (select count(*) from sysobjects where name like 'CD_FONDOS_CodTpCotizacionRecepMon_1') = 0
    ALTER TABLE FONDOSREAL
        ADD CONSTRAINT 	CD_FONDOS_CodTpCotizacionRecepMon_1 DEFAULT 'VP' FOR CodTpCotizacionRecepMon
----------
GO

IF (select count(*) from sysobjects where name like 'CD_FONDOS_CodTpRecepcionTit') <> 0
    ALTER TABLE FONDOSREAL
        DROP CD_FONDOS_CodTpRecepcionTit
go

IF (select count(*) from sysobjects where name like 'CD_FONDOSREAL_CodTpRecepcionTit_1') = 0
    ALTER TABLE FONDOSREAL
        ADD CONSTRAINT 	CD_FONDOSREAL_CodTpRecepcionTit_1 DEFAULT 'NR' FOR CodTpRecepcionTit

GO

IF (select count(*) from sysobjects where name like 'CD_FONDOSREAL_CodTpReintegroGastoResc_1') <> 0
    ALTER TABLE FONDOSREAL
        DROP CD_FONDOSREAL_CodTpReintegroGastoResc_1
go

IF (select count(*) from sysobjects where name like 'CD_FONDOSREAL_CodTpReintegroGastoResc_1') = 0
    ALTER TABLE FONDOSREAL
        ADD CONSTRAINT 	CD_FONDOSREAL_CodTpReintegroGastoResc_1 DEFAULT 'SINREI' FOR CodTpReintegroGastoResc

go
SET NOCOUNT ON
GO

DECLARE @CodFondo CodigoMedio
DECLARE @CodTpValorCp CodigoMedio
DECLARE @MinCodFondo CodigoMedio

DECLARE @NumFondo CodigoMedio
DECLARE @Nombre DescripcionMedia
DECLARE @NombreCorto AbreviaturaLarga
DECLARE @NombreAbreviado AbreviaturaMedia
DECLARE @CodAgColocador CodigoMedio
DECLARE @CodSociedadGte CodigoMedio
DECLARE @CodMoneda CodigoMedio
DECLARE @Fecha smalldatetime
DECLARE @CodAuditoriaRef CodigoLargo
DECLARE @CodAudRefMONEDA CodigoLargo
DECLARE @CodCondicionIngEgr CodigoMedio
DECLARE @CodTpCosto CodigoTextoCorto

-- ESTO NO SE UTILIZARA MAS!!!!!!!!
-- EL CLIENTE DEBE INDICAR EL NUMERO DE FONDO A CREAR
SELECT @NumFondo = 19  --numero de fondo de apertura

-- VALIDO QUE EL FONDO NO EXISTA
IF EXISTS (SELECT * FROM FONDOSREAL WHERE NumFondo = @NumFondo)
    BEGIN
		RAISERROR('El Número de Fondo que intenta crear ya existe en la Base de Datos.', 16, 1) 
    END
--############################
ELSE
	BEGIN
		SELECT @Nombre = 'QUINQUELA RENTA MIXTA SUSTENTABLE FONDO COMÚN DE INVERSIÓN ASG'  --nombre del fondo
		SELECT @NombreCorto = 'QUINQUELA RENTA MIXTA SUSTENTABLE FONDO COMÚN DE INVERSIÓN ASG'  -- nombre del fondo 
		SELECT @NombreAbreviado = 'F' + CONVERT(varchar,@NumFondo)
		SELECT @CodAgColocador = (SELECT MIN(CodAgColocador) FROM AGCOLOCADORES WHERE EstaAnulado = 0)
		SELECT @CodSociedadGte = (SELECT MIN(CodSociedadGte) FROM SOCIEDADESGTE WHERE EstaAnulado = 0)
		
		-- LA MONEDA EN CASO DE SER PESOS SERA TOMADA DE LA APLICACION
		--set @CodAudRefMONEDA = 226 -- es en dolares u otra moneda el id 
		set @CodAudRefMONEDA = 0 -- si es pesos va este
		if @CodAudRefMONEDA = 0
			SELECT @CodMoneda = dbo.fnMonPaisAplicacion()
		else
			SELECT @CodMoneda = CodMoneda from MONEDAS where CodAuditoriaRef = @CodAudRefMONEDA  and EstaAnulado = 0
			
		if COALESCE(@CodMoneda, 0) = 0
		begin
			RAISERROR('El Código de la Moneda no puede ser Nulo o 0 (cero).', 16, 1) 
		end
		else
		begin
		
			-----------------------
			-- TABLA: FONDOSREAL --
			-----------------------
			SELECT 'Insertando Fondo ' + convert(varchar(10),@NumFondo)

			INSERT AUDITORIASREF (NomEntidad)
						  VALUES ('FDO')
			SELECT @CodAuditoriaRef =  @@IDENTITY

			if exists (select * from TPCOSTO where CodTpCosto = 'NB')
			begin
				set @CodTpCosto = 'NB'
			end
			else
			begin
				set @CodTpCosto = 'RT'
			end 

			INSERT FONDOSREAL (CodTpCosto,CodTpDevengamiento,CodTpManejoCert,CodTpFondo,CodTpProvision,CodTpRecepcionTit,
							   CodAgColocadorDep,CodSociedadGte,CodMoneda,Nombre,NombreCorto,NombreAbreviado,NumFondo,
							   CodTpCuotaparte,EsAbierto, CodAuditoriaRef) 
					   VALUES (@CodTpCosto,'LD','ES','MI','DI','TI',
							   @CodAgColocador,@CodSociedadGte,@CodMoneda,@Nombre,@NombreCorto,@NombreAbreviado,@NumFondo,
							   'UN',-1, @CodAuditoriaRef)


			SELECT @CodFondo = (SELECT MAX(CodFondo) FROM FONDOSREAL)
			SELECT @MinCodFondo = (SELECT MIN(CodFondo) FROM FONDOSREAL)

			INSERT AGCOLOCFONDOS (CodFondo, CodAgColocador, EstaAnulado)
			VALUES (@CodFondo, @CodAgColocador, 0)

			INSERT AGCOLOCFDONUMERACIONES (CodFondo,CodAgColocador,CodElNumerable,UltimoNumero,CodTpNumeracion)
			select @CodFondo,@CodAgColocador,CodElNumerable,0,CodTpNumeracionOmision 
			FROM ELNUMERABLES
			WHERE Asociaciones = 7

			---------------------------
			-- TABLA : TPDATOUSERFDO --
			---------------------------

			INSERT INTO AUDITORIASREF (NomEntidad) VALUES ('TPDATOUSERFDO')
			SELECT @CodAuditoriaRef = @@IDENTITY

			INSERT INTO TPDATOSUSERFDO (CodTpDato, CodFondo, LongitudChar, EnterosNumericos, DecimalesNumericos, Alineacion, ConSignoMenos, CodAuditoriaRef)
			VALUES (61, @CodFondo, NULL, 19, 6, 1, 0, @CodAuditoriaRef)

			INSERT INTO AUDITORIASHIST (CodAccion, CodAuditoriaRef, CodUsuario, Fecha, Terminal) 
			VALUES ('TPDATOUSERFDOa', @CodAuditoriaRef , 1, getdate(), host_name())

			-------------------------------
			-- TABLA : CONDICIONESINGEGR --
			-------------------------------

			SELECT 'Insertando la Condición de Ingreso/Egreso'

			INSERT AUDITORIASREF (NomEntidad)
						  VALUES ('CONDINGEGR')
			SELECT @CodAuditoriaRef =  @@IDENTITY

			INSERT CONDICIONESINGEGR (CodFondo, CodTpGtoAdquisicionSusc, CodTpGtoAdquisicionResc, CodTpComDesempeno,
									  Descripcion, DiasPermanenciaFija, EsHabilDiasPermanencia, PorcComSuscripcion, 
									  PorcComRescate, PorcComDesempeno, PorcRetornoBase, RescateMinimo, RescateMaximo, 
									  SuscripcionMinima, SuscripcionMaxima, CobraGtoBancarioSusc, CobraGtoBancarioResc, 
									  GtoBancarioSusc, GtoBancarioResc, CodInterfaz, EstaAnulado, CodAuditoriaRef, 
									  EsPermanenciaMinima, EsPermanenciaRenovable)
							  VALUES (@CodFondo, 'SC', 'SC', 'SC', 
									  'UNICO', 0, 0, 0, 
									  0, 0, 0, 0, -1, 
									  0, -1, 0, 0,
									  NULL, NULL, NULL, 0, @CodAuditoriaRef,
									  0,0)

			SELECT @CodCondicionIngEgr = @@IDENTITY

			-------------------------
			-- TABLA : TPVALORESCP --
			-------------------------

			SELECT @Fecha = CONVERT(Varchar(8), getdate(), 112)
			SELECT 'Insertando el valor de cuotaparte para el día ' + convert(varchar(20),@Fecha,107)

			INSERT AUDITORIASREF (NomEntidad)
						  VALUES ('TPVALCP')
			SELECT @CodAuditoriaRef =  @@IDENTITY
			            
			INSERT TPVALORESCP (CodFondo, Descripcion, Abreviatura, CodAuditoriaRef, ValorCpInicial, FechaInicio, PorMaxHonSocGer, PorMaxHonSocDep, PorMaxGtoSocDep, PorMaxGtoSocGer)
						VALUES (@CodFondo, 'Unico', 'U', @CodAuditoriaRef, 1, @Fecha, 0, 0, 0, 0)

			INSERT AUDITORIASHIST (CodAccion, CodUsuario, Fecha, Terminal, CodAuditoriaRef)
						   VALUES ('TPVALCPa',1,GETDATE(),Host_name(),@CodAuditoriaRef)

			SELECT @CodTpValorCp = MAX(CodTpValorCp)
			FROM TPVALORESCP
			WHERE CodFondo = @CodFondo

			INSERT CONDINGEGRTPVALORESCP (CodFondo, CodCondicionIngEgr, CodTpValorCp, EsDefault, EstaAnulado)
			VALUES (@CodFondo, @CodCondicionIngEgr, @CodTpValorCp, -1, 0)

			------------------------
			-- TABLA : FONDOSPROC --
			------------------------

			SELECT 'Insertando valores en tablas relacionadas'
			         
			INSERT FONDOSPROC (CodFondo,CodProceso,CodUserUltCorrida,FechaUltCorrida,TermUltCorrida,EstaActivo,HayQueProcesar,CodUsuarioU,FechaU,TermU)
			SELECT @CodFondo,CodProceso,NULL,NULL,NULL,0,0,NULL,NULL,NULL FROM PROCESOS

			-------------------------
			-- TABLA : REPORTESFDO --
			-------------------------

			INSERT REPORTESFDO (CodReporte,CodFondo,CodUsuarioUltimaImpresion,FechaUltImpresion,TermUltImpresion) 
			SELECT CodReporte, @CodFondo, NULL, NULL, NULL FROM REPORTESFDO WHERE CodFondo = @MinCodFondo

			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'VCP',1,'ACTIVO',-1,'AC','010000000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'VCP',2,'INVERSIONES',0,'IN','010100000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'VCP',1,'PASIVO',-1,'PA','020000000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'VCP',2,'PROVISIONES',0,'PR','020100000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',1, 'ACTIVO',-1,'AC','010000000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',2, 'ACTIVOS EN EL PAIS',-1,'AP','010100000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'DISPONIBILIDADES',-1,'01','010101000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'VALORES SECTOR PUBLICO',-1,'02','010102000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'VALORES SECTOR PRIVADO',-1,'03','010103000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'VALORES EMITIDAS EN EL PAIS POR ENTIDADES DEL EXTERIOR',-1,'04','010104000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'COLOCACIONES BANCARIAS',-1,'05','010105000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'OTROS',-1,'06','010106000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',2, 'ACTIVOS EN EL EXTERIOR',-1,'AE','010200000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'SECTOR PUBLICO',-1,'07','010201000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'SECTOR PRIVADO',-1,'08','010202000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',1, 'PASIVO',-1,'PA','020000000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',2, 'PASIVOS EN EL PAIS',-1,'PP','020100000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'EMPRESTITOS CONTRATADOS',-1,'09','020101000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'OTROS PASIVOS POR INVERSIONES',-1,'10','020102000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'COMISIONES, TRIBUTOS Y OTROS GASTOS A PAGAR',-1,'11','020103000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'OTROS PASIVOS EN EL PAIS',-1,'12','020104000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',2, 'PASIVOS EN EL EXTERIOR',-1,'PE','020200000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'EMPRESTITOS CONTRATADOS',-1,'13','020201000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'OTROS PASIVOS EN EL EXTERIOR POR INVERSIONES',-1,'14','020202000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO1',3, 'OTROS PASIVOS EN EL EXTERIOR',-1,'15','020203000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',1, 'ACTIVO',-1,'AC','010000000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',2, 'ACTIVOS EN EL PAIS',-1,'AP','010100000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'DISPONIBILIDADES',-1,'01','010101000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'VALORES SECTOR PUBLICO',-1,'02','010102000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'VALORES SECTOR PRIVADO',-1,'03','010103000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'VALORES EMITIDAS EN EL PAIS POR ENTIDADES DEL EXTERIOR',-1,'04','010104000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'COLOCACIONES BANCARIAS',-1,'05','010105000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'OTROS',-1,'06','010106000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',2, 'ACTIVOS EN EL EXTERIOR',-1,'AE','010200000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'SECTOR PUBLICO',-1,'07','010201000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'SECTOR PRIVADO',-1,'08','010202000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',1, 'PASIVO',-1,'PA','020000000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',2, 'PASIVOS EN EL PAIS',-1,'PP','020100000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'EMPRESTITOS CONTRATADOS',-1,'09','020101000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'OTROS PASIVOS POR INVERSIONES',-1,'10','020102000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'COMISIONES, TRIBUTOS Y OTROS GASTOS A PAGAR',-1,'11','020103000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'OTROS PASIVOS EN EL PAIS',-1,'12','020104000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',2, 'PASIVOS EN EL EXTERIOR',-1,'PE','020200000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'EMPRESTITOS CONTRATADOS',-1,'13','020201000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'OTROS PASIVOS EN EL EXTERIOR POR INVERSIONES',-1,'14','020202000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL)
			INSERT RUBROSRPT (CodFondo,CodReporte,Nivel,Descripcion,TieneSubrubros,RubroID,Orden,CodUsuarioI,CodUsuarioU,FechaI,FechaU,TermI,TermU) VALUES (@CodFondo,'COMPO2',3, 'OTROS PASIVOS EN EL EXTERIOR',-1,'15','020203000000000000',1,NULL,GETDATE(),NULL,HOST_NAME(),NULL) 

			INSERT TPDEVOPERACIONESFDO (CodFondo, CodOperacionDev, CodTpDevengamiento)
			SELECT DISTINCT @CodFondo, TPDEVOPERACIONES.CodOperacionDev, 'LD'
			FROM TPDEVOPERACIONES

			------------------------------
			-- TABLA : REPORTESFDOPARAM --
			------------------------------

			INSERT REPORTESFDOPARAM (CodFondo,CodReporte,CodParametroRpt,ValorParametro,CodUsuarioU,FechaU,TermU) 
			SELECT @CodFondo,CodReporte,CodParametroRpt,NULL,NULL,NULL,NULL FROM REPORTESFDOPARAM WHERE CodFondo = @MinCodFondo

			UPDATE REPORTESFDOPARAM SET ValorParametro = (SELECT CONVERT(varchar(255),PorOmision) FROM PARAMETROSRPT where PARAMETROSRPT.CodParametroRpt = REPORTESFDOPARAM.CodParametroRpt) where CodFondo = @CodFondo

			------------------------
			-- TABLA : FONDOSUSER --
			------------------------

			INSERT FONDOSUSER
				(CodFondo, CodUsuario)
			SELECT @CodFondo, CodUsuario FROM USUARIOSREL
			WHERE USUARIOSREL.CodTpUsuario='CO'

			SELECT 'Se ha insertado correctamente el Fondo ' + convert(varchar(10),@NumFondo)
		end
		
	end


	GO

DECLARE @NumFondo NumeroLargo
DECLARE @CodFondo NumeroLargo
DECLARE @CantTpValorCpNuevo NumeroLargo
DECLARE @Abreviatura AbreviaturaLarga
DECLARE @Descripcion DescripcionLarga
DECLARE @Cantidad NumeroLargo
DECLARE @Encontrado Boolean
DECLARE @Fecha Fecha
DECLARE @CodAuditoriaRef CodigoLargo
DECLARE @ValorInicial Precio

--Indicar el Numero de Fondo donde se agregan las cuotapartes a Generar
SELECT @NumFondo = 19 --nuevamente el nro de fondo

--Indicar Cantidad de Cuotas a Generar -1 recordar 
SELECT @CantTpValorCpNuevo = 2 --aca va desde -1 si va con un fondo nuevo si es 4 -1 seria 3

SELECT @CodFondo = CodFondo
FROM FONDOS
WHERE NumFondo = @NumFondo

SELECT @Cantidad = 0
SELECT @ValorInicial = 1

WHILE @CantTpValorCpNuevo <> 0
BEGIN

    SELECT @Encontrado = 0
    WHILE @Encontrado = 0
    BEGIN

        SELECT @Descripcion = 'Clase ' + CHAR(ASCII('A') + @Cantidad)
        SELECT @Abreviatura = CHAR(ASCII('A') + @Cantidad)
    
        SELECT @Cantidad = @Cantidad + 1
        
        IF (SELECT COUNT(*) FROM TPVALORESCP WHERE Descripcion = @Descripcion and @CodFondo = CodFondo) = 0
        BEGIN
            IF (SELECT COUNT(*) FROM TPVALORESCP WHERE Abreviatura = @Abreviatura and @CodFondo = CodFondo)= 0
            BEGIN
                SELECT @Encontrado = -1
            END
        END

    END

    SELECT @Fecha = CONVERT(Varchar(8), getdate(), 112)
    SELECT 'Insertando el valor de cuotaparte para el día ' + convert(varchar(20),@Fecha,107)

    INSERT AUDITORIASREF (NomEntidad)
        VALUES ('TPVALCP')

    SELECT @CodAuditoriaRef =  @@IDENTITY
            
	INSERT TPVALORESCP (CodFondo, Descripcion, Abreviatura, CodAuditoriaRef, ValorCpInicial, FechaInicio, PorMaxHonSocGer, PorMaxHonSocDep, PorMaxGtoSocDep, PorMaxGtoSocGer) 
        VALUES (@CodFondo, @Descripcion, @Abreviatura, @CodAuditoriaRef, @ValorInicial, @Fecha, 0, 0, 0, 0)

    INSERT AUDITORIASHIST (CodAccion, CodUsuario, Fecha, Terminal, CodAuditoriaRef)
        VALUES ('TPVALCPa',1,GETDATE(),Host_name(),@CodAuditoriaRef)

    SELECT @CantTpValorCpNuevo = @CantTpValorCpNuevo - 1

END

IF (SELECT COUNT(*) FROM FONDOSREAL WHERE CodTpCuotaparte = 'UN' and CodFondo = @CodFondo )= 1 BEGIN
	UPDATE FONDOS 
		SET CodTpCuotaparte = 'MVPAT'
	WHERE CodFondo = @CodFondo
END


GO

--if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#CTASCONTABLES')) BEGIN
--    DROP TABLE #CTASCONTABLES
--END

--alter table CTASCONTABLES nocheck constraint CFK_CTASCONTABLES_CTASCONTABLES_1

--GO

--DECLARE @CodCtaContable CodigoCuentaContable
--DECLARE @CodFondoDesde CodigoMedio
--DECLARE @CodFondoHasta CodigoMedio
--DECLARE @CodAuditoriaRef CodigoLargo


--SELECT @CodFondoDesde = CodFondo from FONDOSREAL where NumFondo = 18 --desde fondos
--SELECT @CodFondoHasta = CodFondo from FONDOSREAL where NumFondo = 19 -- hasta fondo

--SELECT * 
--INTO #CTASCONTABLES
--FROM CTASCONTABLES
--WHERE CodFondo = @CodFondoDesde AND EstaAnulado = 0

--WHILE (SELECT COUNT(*) FROM #CTASCONTABLES) > 0  BEGIN
--    SELECT @CodCtaContable = CodCtaContable
--    FROM #CTASCONTABLES
--    ORDER BY CodPadre Desc
	
--    INSERT AUDITORIASREF (NomEntidad)
--    VALUES ('CTACONT')
--    SELECT @CodAuditoriaRef = @@IDENTITY

--    INSERT CTASCONTABLES (CodFondo, CodCtaContable, CodAgente, CodBanco, CodTpEspecie, CodTpCtaAutomatica,
--                          CodTpOperacion, CodEspecie, CodSerie, Nivel, Descripcion, Alias, TieneSubrubros,
--                          CodMoneda, CodTpCtaContable, AjustaInflacion, IntervieneEnCashFlow, IntervieneEnProv,
--                          CodTpValorCp, EstaAnulado, CodAuditoriaRef, CodPadre, CodTpPlanCtaContable)

--    SELECT @CodFondoHasta, CodCtaContable, CodAgente, CodBanco, CodTpEspecie, (case when NOT CodCtaBancaria IS NULL THEN NULL ELSE CodTpCtaAutomatica END),
--           CodTpOperacion, CodEspecie, CodSerie, Nivel, Descripcion, Alias, TieneSubrubros,
--           (case when TieneSubrubros = -1 THEN NULL ELSE CodMoneda END), CodTpCtaContable, AjustaInflacion, IntervieneEnCashFlow, IntervieneEnProv,
--           null, 0, @CodAuditoriaRef, CodPadre, CodTpPlanCtaContable          
--    FROM #CTASCONTABLES
--    WHERE @CodCtaContable = CodCtaContable
    
--    INSERT AUDITORIASHIST (CodAccion, CodUsuario, Fecha, Terminal, CodAuditoriaRef)
--                   VALUES ('CTACONTa', 1, Getdate(), Host_name(), @CodAuditoriaRef)

--    DELETE #CTASCONTABLES
--    WHERE @CodCtaContable = CodCtaContable
--END

--GO

--alter table CTASCONTABLES check constraint CFK_CTASCONTABLES_CTASCONTABLES_1

--GO

if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOAGCOLOCPARAM'))
	drop table #FORMULARIOSFDOAGCOLOCPARAM
GO
if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOPARAM'))
	DROP TABLE #FORMULARIOSFDOPARAM
GO
if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOELCOND'))
	DROP TABLE #FORMULARIOSFDOELCOND
GO
if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOBLOQCOND'))
	DROP TABLE #FORMULARIOSFDOBLOQCOND
GO
if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOELEMENTO'))
	DROP TABLE #FORMULARIOSFDOELEMENTO
GO
if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDO'))
	DROP TABLE #FORMULARIOSFDO
GO
if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FONDOSHASTA'))
	DROP TABLE #FONDOSHASTA
go
if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOBLOQUE'))
	DROP TABLE #FORMULARIOSFDOBLOQUE
go
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDO'))
	CREATE TABLE #FORMULARIOSFDO(CodFondo numeric(5, 0), CodFormulario varchar(6), CodUsuarioUltImpresion numeric(10, 0), FechaUltImpresion datetime, TermUltImpresion varchar(15))
GO
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FONDOSHASTA'))
	CREATE TABLE #FONDOSHASTA(CodFondo Numeric(10))
GO
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOBLOQUE'))
	CREATE TABLE #FORMULARIOSFDOBLOQUE(CodFondo numeric(5, 0), CodFormulario varchar(6), CodBloque numeric(3, 0))
GO
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOELEMENTO'))
	CREATE TABLE #FORMULARIOSFDOELEMENTO(CodFondo numeric(5, 0), CodFormulario varchar(6), CodBloque numeric(3, 0), CodElemento numeric(3, 0), TpElemento numeric(2, 0), Alineacion numeric(1, 0), Tamano numeric(2, 0), Fuente varchar(80), Estilo numeric(2, 0), CoordenadaX1 numeric(6, 0), CoordenadaX2 numeric(6, 0), CoordenadaY1 numeric(6, 0), CoordenadaY2 numeric(6, 0), ColorFondo numeric(2, 0), ColorTrazo numeric(2, 0), CodVariable varchar(6), Texto varchar(2000), CodUsuarioI numeric(10, 0), FechaI datetime, TermI varchar(15), CodUsuarioU numeric(10, 0), FechaU datetime, TermU varchar(15), Formato varchar(80), CodFrmGrafico varchar(6), TextoAngulo numeric(5, 0))
GO
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOBLOQCOND'))
	CREATE TABLE #FORMULARIOSFDOBLOQCOND(CodFondo numeric(5, 0), CodFormulario varchar(6), CodBloque numeric(3, 0), CodFormularioFdoBloqCond numeric(5, 0) IDENTITY(1, 1), CodCondicion varchar(6), CodVariable varchar(6), CodVariableComp varchar(6))
GO
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOELCOND'))
	CREATE TABLE #FORMULARIOSFDOELCOND(CodFondo numeric(5, 0), CodFormulario varchar(6), CodBloque numeric(3, 0), CodElemento numeric(3, 0), CodFormularioFdoElCond numeric(5, 0) IDENTITY(1, 1), CodCondicion varchar(6), CodVariable varchar(6), CodVariableComp varchar(6), Valor varchar(2000))
GO
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOPARAM'))
	CREATE TABLE #FORMULARIOSFDOPARAM(CodFondo numeric(5, 0), CodFormulario varchar(6), CodParametroFrm varchar(6), ValorParametro varchar(2000), CodUsuarioU numeric(10, 0), FechaU datetime, TermU varchar(15))
GO
if not exists (select * from tempdb..sysobjects where id = object_id('tempdb..#FORMULARIOSFDOAGCOLOCPARAM'))
	CREATE TABLE #FORMULARIOSFDOAGCOLOCPARAM(CodFondo numeric(5, 0), CodFormulario varchar(6), CodAgColocador numeric(5,0), CodParametroFrm varchar(6), ValorParametro varchar(2000), CodUsuarioU numeric(10, 0), FechaU datetime, TermU varchar(15))
GO


DECLARE @HayError Integer
DECLARE @CodigoFondoFuente CodigoMedio

SELECT @CodigoFondoFuente = CodFondo FROM FONDOSREAL WHERE NumFondo = 18 -- Fondo desde el que se copia

/*cuando quiero insertar a algunos fondos
INSERT  #FONDOSHASTA VALUES (2)*/

/*cuando quiero insertar a todos los fondos */
INSERT  #FONDOSHASTA
	select CodFondo FROM FONDOSREAL WHERE NumFondo = 19 -- Fondo Nuevo hasta el que se copia
/**/

SELECT @HayError = 0

/*DELETE FORMULARIOSFDOPARAM WHERE CodFondo in (select CodFondo FROM #FONDOSHASTA)
DELETE FORMULARIOSFDOELCOND WHERE CodFondo in (select CodFondo FROM #FONDOSHASTA)
DELETE FORMULARIOSFDOELEMENTO WHERE CodFondo in (select CodFondo FROM #FONDOSHASTA)
DELETE FORMULARIOSFDOBLOQCOND WHERE CodFondo in (select CodFondo FROM #FONDOSHASTA)
DELETE FORMULARIOSFDOBLOQUE WHERE CodFondo in (select CodFondo FROM #FONDOSHASTA)
DELETE FORMULARIOSFDO WHERE CodFondo in (select CodFondo FROM #FONDOSHASTA)
*/
/*##########################################*/
INSERT #FORMULARIOSFDO (CodFondo, CodFormulario, CodUsuarioUltImpresion, FechaUltImpresion, TermUltImpresion)
	SELECT #FONDOSHASTA.CodFondo, CodFormulario, 1, GETDATE(), HOST_NAME()
	FROM FORMULARIOSFDO, #FONDOSHASTA WHERE FORMULARIOSFDO.CodFondo = @CodigoFondoFuente
	UNION 
	SELECT CodFondo, CodFormulario, 1, GETDATE(), HOST_NAME()
	FROM FORMULARIOSFDO WHERE CodFondo = @CodigoFondoFuente

INSERT #FORMULARIOSFDOBLOQUE (CodFondo, CodFormulario, CodBloque)
	SELECT #FONDOSHASTA.CodFondo, CodFormulario, CodBloque
	FROM FORMULARIOSFDOBLOQUE, #FONDOSHASTA WHERE FORMULARIOSFDOBLOQUE.CodFondo = @CodigoFondoFuente
	UNION 
	SELECT CodFondo, CodFormulario, CodBloque
	FROM FORMULARIOSFDOBLOQUE WHERE CodFondo = @CodigoFondoFuente

INSERT #FORMULARIOSFDOELEMENTO
	(CodFondo, CodFormulario, CodBloque, CodElemento, TpElemento,Alineacion, Tamano, Fuente, Estilo, CoordenadaX1, CoordenadaX2,CoordenadaY1, CoordenadaY2, ColorFondo, ColorTrazo, CodVariable,Texto, CodUsuarioI, FechaI, TermI, CodUsuarioU, FechaU, TermU,Formato, CodFrmGrafico)
	SELECT #FONDOSHASTA.CodFondo, CodFormulario, CodBloque, CodElemento, TpElemento,Alineacion, Tamano, Fuente, Estilo, CoordenadaX1, CoordenadaX2,CoordenadaY1, CoordenadaY2, ColorFondo, ColorTrazo, CodVariable,Texto, CodUsuarioI, FechaI, TermI, CodUsuarioU, FechaU, TermU,Formato, CodFrmGrafico
	FROM FORMULARIOSFDOELEMENTO, #FONDOSHASTA WHERE FORMULARIOSFDOELEMENTO.CodFondo = @CodigoFondoFuente
	UNION
	SELECT CodFondo, CodFormulario, CodBloque, CodElemento, TpElemento,Alineacion, Tamano, Fuente, Estilo, CoordenadaX1, CoordenadaX2,CoordenadaY1, CoordenadaY2, ColorFondo, ColorTrazo, CodVariable,Texto, CodUsuarioI, FechaI, TermI, CodUsuarioU, FechaU, TermU,Formato, CodFrmGrafico
	FROM FORMULARIOSFDOELEMENTO WHERE CodFondo = @CodigoFondoFuente

INSERT #FORMULARIOSFDOPARAM
	(CodFondo, CodFormulario, CodParametroFrm, ValorParametro,CodUsuarioU, FechaU, TermU)
	SELECT #FONDOSHASTA.CodFondo, CodFormulario, CodParametroFrm, ValorParametro, 1 , GETDATE(), HOST_NAME()
	FROM FORMULARIOSFDOPARAM, #FONDOSHASTA WHERE FORMULARIOSFDOPARAM.CodFondo = @CodigoFondoFuente
	UNION 
	SELECT CodFondo, CodFormulario, CodParametroFrm, ValorParametro, 1 , GETDATE(), HOST_NAME()
	FROM FORMULARIOSFDOPARAM WHERE CodFondo = @CodigoFondoFuente

INSERT #FORMULARIOSFDOAGCOLOCPARAM
	(CodFondo, CodFormulario, CodAgColocador, CodParametroFrm, ValorParametro,CodUsuarioU, FechaU, TermU)
	SELECT #FONDOSHASTA.CodFondo, CodFormulario, CodAgColocador, CodParametroFrm, ValorParametro, 1 , GETDATE(), HOST_NAME()
	FROM FORMULARIOSFDOAGCOLOCPARAM, #FONDOSHASTA 
	WHERE FORMULARIOSFDOAGCOLOCPARAM.CodFondo = @CodigoFondoFuente
	UNION 
	SELECT CodFondo, CodFormulario, CodAgColocador, CodParametroFrm, ValorParametro, 1 , GETDATE(), HOST_NAME()
	FROM FORMULARIOSFDOAGCOLOCPARAM WHERE CodFondo = @CodigoFondoFuente
	
INSERT #FORMULARIOSFDOELCOND 
	(CodFondo, CodFormulario, CodBloque, CodElemento,CodCondicion, CodVariable, CodVariableComp, Valor)
	SELECT #FONDOSHASTA.CodFondo,  CodFormulario, CodBloque, CodElemento,CodCondicion , CodVariable, CodVariableComp, Valor
	FROM FORMULARIOSFDOELCOND , #FONDOSHASTA
	WHERE FORMULARIOSFDOELCOND.CodFondo = @CodigoFondoFuente
	UNION
	SELECT CodFondo,  CodFormulario, CodBloque, CodElemento,CodCondicion , CodVariable, CodVariableComp, Valor
	FROM FORMULARIOSFDOELCOND 
	WHERE CodFondo = @CodigoFondoFuente

INSERT #FORMULARIOSFDOBLOQCOND 
	(CodFondo, CodFormulario, CodBloque,CodCondicion, CodVariable, CodVariableComp)
	SELECT #FONDOSHASTA.CodFondo , CodFormulario, CodBloque,CodCondicion , CodVariable, CodVariableComp
	FROM FORMULARIOSFDOBLOQCOND  , #FONDOSHASTA
	WHERE FORMULARIOSFDOBLOQCOND.CodFondo = @CodigoFondoFuente
	UNION
	SELECT CodFondo , CodFormulario, CodBloque,CodCondicion , CodVariable, CodVariableComp
	FROM FORMULARIOSFDOBLOQCOND 
	WHERE CodFondo = @CodigoFondoFuente

DELETE FORMULARIOSFDOAGCOLOCPARAM WHERE CodFondo = @CodigoFondoFuente
DELETE FORMULARIOSFDOPARAM WHERE CodFondo = @CodigoFondoFuente
DELETE FORMULARIOSFDOELCOND WHERE CodFondo = @CodigoFondoFuente
DELETE FORMULARIOSFDOELEMENTO WHERE CodFondo = @CodigoFondoFuente
DELETE FORMULARIOSFDOBLOQCOND WHERE CodFondo = @CodigoFondoFuente
DELETE FORMULARIOSFDOBLOQUE WHERE CodFondo = @CodigoFondoFuente
DELETE FORMULARIOSFDO WHERE CodFondo = @CodigoFondoFuente

INSERT  FORMULARIOSFDO (CodFondo,CodFormulario,CodUsuarioUltImpresion,FechaUltImpresion,TermUltImpresion) 
SELECT CodFondo,CodFormulario,CodUsuarioUltImpresion,FechaUltImpresion,TermUltImpresion FROM #FORMULARIOSFDO

INSERT  FORMULARIOSFDOBLOQUE (CodFondo,CodFormulario,CodBloque) 
SELECT CodFondo,CodFormulario,CodBloque FROM #FORMULARIOSFDOBLOQUE

INSERT  FORMULARIOSFDOELEMENTO (CodFondo,CodFormulario,CodBloque,CodElemento,TpElemento,Alineacion,Tamano,Fuente,Estilo,CoordenadaX1,CoordenadaX2,CoordenadaY1,CoordenadaY2,ColorFondo,ColorTrazo,CodVariable,Texto,CodUsuarioI,FechaI,TermI,CodUsuarioU,FechaU,TermU,Formato,CodFrmGrafico,TextoAngulo) 
SELECT CodFondo,CodFormulario,CodBloque,CodElemento,TpElemento,Alineacion,Tamano,Fuente,Estilo,CoordenadaX1,CoordenadaX2,CoordenadaY1,CoordenadaY2,ColorFondo,ColorTrazo,CodVariable,Texto,CodUsuarioI,FechaI,TermI,CodUsuarioU,FechaU,TermU,Formato,CodFrmGrafico,TextoAngulo FROM #FORMULARIOSFDOELEMENTO

SET identity_insert FORMULARIOSFDOBLOQCOND ON
INSERT  FORMULARIOSFDOBLOQCOND (CodFondo,CodFormulario,CodBloque,CodFormularioFdoBloqCond,CodCondicion,CodVariable,CodVariableComp) 
SELECT CodFondo,CodFormulario,CodBloque,CodFormularioFdoBloqCond,CodCondicion,CodVariable,CodVariableComp FROM #FORMULARIOSFDOBLOQCOND
SET identity_insert FORMULARIOSFDOBLOQCOND OFF

SET identity_insert FORMULARIOSFDOELCOND ON
INSERT  FORMULARIOSFDOELCOND (CodFondo,CodFormulario,CodBloque,CodElemento,CodFormularioFdoElCond,CodCondicion,CodVariable,CodVariableComp,Valor) 
SELECT CodFondo,CodFormulario,CodBloque,CodElemento,CodFormularioFdoElCond,CodCondicion,CodVariable,CodVariableComp,Valor FROM #FORMULARIOSFDOELCOND
SET identity_insert FORMULARIOSFDOELCOND OFF

INSERT  FORMULARIOSFDOPARAM (CodFondo,CodFormulario,CodParametroFrm,ValorParametro,CodUsuarioU,FechaU,TermU) 
SELECT CodFondo,CodFormulario,CodParametroFrm,ValorParametro,CodUsuarioU,FechaU,TermU FROM #FORMULARIOSFDOPARAM

INSERT  FORMULARIOSFDOAGCOLOCPARAM (CodFondo,CodFormulario,CodAgColocador,CodParametroFrm,ValorParametro,CodUsuarioU,FechaU,TermU) 
SELECT CodFondo,CodFormulario,CodAgColocador,CodParametroFrm,ValorParametro,CodUsuarioU,FechaU,TermU FROM #FORMULARIOSFDOAGCOLOCPARAM

GO
