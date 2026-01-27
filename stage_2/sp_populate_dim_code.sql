CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_code
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_code') IS NOT NULL
        DROP TABLE #src_code;

    CREATE TABLE #src_code
    (
        code_type VARCHAR(10) NOT NULL,
        code_short VARCHAR(10) NOT NULL,
        code_long VARCHAR(60) NOT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(code_type, '') + '|' +
                COALESCE(code_short, '') + '|' +
                COALESCE(code_long, '')
            )
        ) PERSISTED,
        PRIMARY KEY (code_type, code_short)
    );

    -- Insert root codes
    INSERT INTO #src_code (code_type, code_short, code_long)
    VALUES
        ('root', 'AC', 'AIR SYSTEM COMPRESSOR'),
        ('root', 'ACA', 'AIR SYSTEM COMPRESSOR HEAD'),
        ('root', 'ACB', 'AIR SYSTEM COMPRESSOR HEAD GASKET'),
        ('root', 'ACC', 'AIR SYSTEM COMPRESSOR PASSING OIL'),
        ('root', 'AP', 'AIR SYSTEM PIPEWORK (INC HOSES)'),
        ('root', 'APA', 'AIR SYSTEM PIPEWORK (INC HOSES) DELIVERY HOSE'),
        ('root', 'APT', 'AIR SYSTEM PIPEWORK (INC HOSES) TRIGGER PIPE'),
        ('root', 'DA', 'DIESEL ENGINE AIR INLET MANIFOLD (INC HOSES)'),
        ('root', 'DAF', 'DIESEL ENGINE AIR INLET MANIFOLD (INC HOSES) AIR FILTER'),
        ('root', 'DB', 'DIESEL ENGINE BREATHER'),
        ('root', 'DBC', 'DIESEL ENGINE BREATHER CRANKCASE'),
        ('root', 'DC', 'DIESEL ENGINE CRANKCASE'),
        ('root', 'DD', 'DIESEL ENGINE CAMSHAFT/DRIVE'),
        ('root', 'DE', 'DIESEL ENGINE EXHAUST'),
        ('root', 'DEA', 'DIESEL ENGINE EXHAUST MANIFOLD CLAMP'),
        ('root', 'DEB', 'DIESEL ENGINE EXHAUST MANIFOLD CRACKED'),
        ('root', 'DEC', 'DIESEL ENGINE EXHAUST GENERAL'),
        ('root', 'DEM', 'DIESEL ENGINE EXHAUST MARRIAGE PLATE'),
        ('root', 'DF', 'DIESEL ENGINE FLYWHEEL'),
        ('root', 'DFH', 'DIESEL ENGINE FLYWHEEL HOLSET COUPLING'),
        ('root', 'DFV', 'DIESEL ENGINE FLYWHEEL VOITH COUPLING'),
        ('root', 'DG', 'DIESEL ENGINE GOVERNOR/FUEL RACK LINKAGE/OVERSPEED UNIT'),
        ('root', 'DH', 'DIESEL ENGINE CYLINDER HEADS'),
        ('root', 'DHB', 'DIESEL ENGINE CYLINDER HEADS  BOLTS'),
        ('root', 'DHG', 'DIESEL ENGINE CYLINDER HEADS  GASKET'),
        ('root', 'DI', 'DIESEL ENGINE ACCESSORY DRIVE'),
        ('root', 'DJ', 'DIESEL ENGINE HIGH OIL USAGE'),
        ('root', 'DK', 'DIESEL ENGINE CHARGE AIR PIPEWORK'),
        ('root', 'DL', 'DIESEL ENGINE CYLINDER LINERS'),
        ('root', 'DM', 'DIESEL ENGINE PUSH RODS/CAM FOLLOWER'),
        ('root', 'DN', 'DIESEL ENGINE INTERCOOLERS'),
        ('root', 'DO', 'DIESEL ENGINE OTHER'),
        ('root', 'DP', 'DIESEL ENGINE PISTON/CONNECTING ROD'),
        ('root', 'DR', 'DIESEL ENGINE ROCKER/VALVE GEAR'),
        ('root', 'DS', 'DIESEL ENGINE SUMP'),
        ('root', 'DSA', 'DIESEL ENGINE SUMP BOLTS'),
        ('root', 'DSB', 'DIESEL ENGINE SUMP CRACKED'),
        ('root', 'DSD', 'DIESEL ENGINE SUMP DIP STICK'),
        ('root', 'DT', 'DIESEL ENGINE TURBOCHARGER'),
        ('root', 'DTA', 'DIESEL ENGINE TURBOCHARGER DIFFUSER RING'),
        ('root', 'DTB', 'DIESEL ENGINE TURBOCHARGER IMPELLOR'),
        ('root', 'DTC', 'DIESEL ENGINE TURBOCHARGER BOOST HOSE'),
        ('root', 'DTD', 'DIESEL ENGINE TURBOCHARGER ANTI ROTATION BRACKET'),
        ('root', 'DTE', 'DIESEL ENGINE TURBOCHARGER COMPRESSOR IMPELLOR CLEANED'),
        ('root', 'DTF', 'DIESEL ENGINE TURBOCHARGER EXHAUST HOUSING BOLTS'),
        ('root', 'DV', 'DIESEL ENGINE VALVES/PIPEWORK'),
        ('root', 'DX', 'DIESEL ENGINE ENGINE CONDEMNED'),
        ('root', 'DY', 'DIESEL ENGINE ENGINE MOUNTINGS'),
        ('root', 'EB', 'BATTERY/CONTROL SYSTEMS BATTERIES/CHARGING'),
        ('root', 'EC', 'BATTERY/CONTROL SYSTEMS THROTTLE CONTROLLER'),
        ('root', 'EH', 'BATTERY/CONTROL SYSTEMS SENSORS'),
        ('root', 'EHA', 'BATTERY/CONTROL SYSTEMS SENSORS  OIL PRESSURE SWITCH'),
        ('root', 'EHB', 'BATTERY/CONTROL SYSTEMS SENSORS  IFU - COOLANT TEMP'),
        ('root', 'EHC', 'BATTERY/CONTROL SYSTEMS SENSORS  EDC - COOLANT TEMP'),
        ('root', 'EHD', 'BATTERY/CONTROL SYSTEMS SENSORS  EDC - CHARGE AIR TEMP'),
        ('root', 'EHE', 'BATTERY/CONTROL SYSTEMS SENSORS  CHARGE AIR PRESSURE'),
        ('root', 'EHF', 'BATTERY/CONTROL SYSTEMS SENSORS  No. 1 INJECTOR'),
        ('root', 'EHG', 'BATTERY/CONTROL SYSTEMS SENSORS  FUEL TEMP SENSOR'),
        ('root', 'EHH', 'BATTERY/CONTROL SYSTEMS SENSORS  AUXILIARY SPEED'),
        ('root', 'EHI', 'BATTERY/CONTROL SYSTEMS SENSORS  CHARGE AIR TEMP'),
        ('root', 'EHJ', 'BATTERY/CONTROL SYSTEMS SENSORS  COOLANT TEMP'),
        ('root', 'EHK', 'BATTERY/CONTROL SYSTEMS SENSORS  ENGINE SPEED SENSOR'),
        ('root', 'EHZ', 'BATTERY/CONTROL SYSTEMS SENSORS  OTHER'),
        ('root', 'EK', 'BATTERY/CONTROL SYSTEMS KROMA SWITCH'),
        ('root', 'ER', 'BATTERY/CONTROL SYSTEMS RELAY'),
        ('root', 'ES', 'BATTERY/CONTROL SYSTEMS SWITCHES/SOCKETS/PLUGS'),
        ('root', 'EU', 'BATTERY/CONTROL SYSTEMS ELECTRONIC MODULES'),
        ('root', 'EUA', 'BATTERY/CONTROL SYSTEMS ELECTRONIC MODULES IFU CARDS'),
        ('root', 'EUC', 'BATTERY/CONTROL SYSTEMS ELECTRONIC MODULES BATT CHARGER'),
        ('root', 'EUJ', 'BATTERY/CONTROL SYSTEMS ELECTRONIC MODULES EDC'),
        ('root', 'EW', 'BATTERY/CONTROL SYSTEMS WIRING'),
        ('root', 'EZ', 'BATTERY/CONTROL SYSTEMS OTHER'),
        ('root', 'LA', 'LUB.OIL/FUEL OIL - FILL'),
        ('root', 'LB', 'LUB.OIL/FUEL OIL - DRAIN'),
        ('root', 'LC', 'LUB.OIL/FUEL FUEL - FILL'),
        ('root', 'LCC', 'LUB.OIL/FUEL FUEL - FILL CONTAMINATION'),
        ('root', 'LD', 'LUB.OIL/FUEL FUEL - DRAIN'),
        ('root', 'LF', 'LUB.OIL/FUEL FILTERS'),
        ('root', 'LFB', 'LUB.OIL/FUEL FILTERS BIOCIDE'),
        ('root', 'LFC', 'LUB.OIL/FUEL FILTERS CENTRIFUGAL OIL FILTER'),
        ('root', 'LFF', 'LUB.OIL/FUEL FILTERS FUEL FILTERS'),
        ('root', 'LFO', 'LUB.OIL/FUEL FILTERS OIL FILTERS'),
        ('root', 'LG', 'LUB.OIL/FUEL SIGHT GLASS'),
        ('root', 'LH', 'LUB.OIL/FUEL HOSES'),
        ('root', 'LHF', 'LUB.OIL/FUEL HOSES  FUEL'),
        ('root', 'LHO', 'LUB.OIL/FUEL HOSES  OIL'),
        ('root', 'LI', 'LUB.OIL/FUEL INJECTION EQUIPMENT (INCL. PUMPS/INJECTORS)'),
        ('root', 'LIA', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) HIGH PRESS FUEL'),
        ('root', 'LIB', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) LOW PRESS FUEL'),
        ('root', 'LIC', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) INJECTOR'),
        ('root', 'LID', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) FUEL RACK'),
        ('root', 'LIE', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) FUEL LIFT PUMP'),
        ('root', 'LIF', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) EHAB SOLENOID'),
        ('root', 'LIG', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) FUEL PUMP'),
        ('root', 'LIH', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) PRIMING PUMP'),
        ('root', 'LIJ', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) IDLE SPEED'),
        ('root', 'LIU', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) EHAB FUEL LINE CTRL'),
        ('root', 'LIV', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) EHAB VALVE'),
        ('root', 'LIW', 'LUB.OIL/FUEL INJ EQUIP (INCL. PUMPS) EHAB SOLENOID WIRE'),
        ('root', 'LJ', 'LUB.OIL/FUEL OIL CONTAMINATION'),
        ('root', 'LK', 'LUB.OIL/FUEL OIL PRESSURE REGULATIOR'),
        ('root', 'LO', 'LUB.OIL/FUEL LUB. OIL PUMP'),
        ('root', 'LP', 'LUB.OIL/FUEL OIL PRESSURE LOW'),
        ('root', 'LQ', 'LUB.OIL/FUEL OIL PRESSURE HIGH'),
        ('root', 'LR', 'LUB.OIL/FUEL OIL COOLER/ HEAT EXCHANGER'),
        ('root', 'LS', 'LUB.OIL/FUEL LEAK'),
        ('root', 'LSA', 'LUB.OIL/FUEL LEAK LUBE OIL'),
        ('root', 'LSB', 'LUB.OIL/FUEL LEAK FUEL'),
        ('root', 'LSC', 'LUB.OIL/FUEL LEAK FILLER CAP'),
        ('root', 'LT', 'LUB.OIL/FUEL FITTINGS'),
        ('root', 'LU', 'LUB.OIL/FUEL PIPEWORK'),
        ('root', 'LV', 'LUB.OIL/FUEL VALVE/SOLENOID'),
        ('root', 'LVA', 'LUB.OIL/FUEL VALVE/SOLENOID ERS'),
        ('root', 'LVC', 'LUB.OIL/FUEL VALVE/SOLENOID AUTOMATIC FUEL CONTROL'),
        ('root', 'LVF', 'LUB.OIL/FUEL VALVE/SOLENOID FUEL'),
        ('root', 'LVM', 'LUB.OIL/FUEL VALVE/SOLENOID MUTC BLOCK'),
        ('root', 'LW', 'LUB.OIL/FUEL FUEL WARMER'),
        ('root', 'LX', 'LUB.OIL/FUEL ADVERSE OIL SAMPLE'),
        ('root', 'MA', 'MACHINES ELECTRICAL ROTATING ALTERNATOR'),
        ('root', 'MAA', 'MACHINES ELECTRICAL ROTATING ALTERNATOR DRIVE COUPLING'),
        ('root', 'MS', 'MACHINES ELECTRICAL ROTATING STARTER MOTOR'),
        ('root', 'NF', 'NO FAULT'),
        ('root', 'NFF', 'NO FAULT FOUND'),
        ('root', 'OS', 'OBJECT STRIKE'),
        ('root', 'QA', 'COOLING/HYDROSTATICS AUXILIARY HEATER'),
        ('root', 'QAA', 'COOLING/HYDROSTATICS AUXILIARY HEATER PIPEWORK'),
        ('root', 'QC', 'COOLING/HYDROSTATICS COOLANT'),
        ('root', 'QCA', 'COOLING/HYDROSTATICS COOLANT FILL'),
        ('root', 'QCB', 'COOLING/HYDROSTATICS COOLANT AUTO BLEED VALVE'),
        ('root', 'QCC', 'COOLING/HYDROSTATICS COOLANT LEAK'),
        ('root', 'QCD', 'COOLING/HYDROSTATICS COOLANT CONTAMINATION'),
        ('root', 'QCE', 'COOLING/HYDROSTATICS COOLANT FILLER CAP'),
        ('root', 'QCF', 'COOLING/HYDROSTATICS COOLANT FILTER'),
        ('root', 'QCL', 'COOLING/HYDROSTATICS COOLANT LEVEL SENSOR'),
        ('root', 'QCM', 'COOLING/HYDROSTATICS COOLANT MANIFOLD'),
        ('root', 'QCS', 'COOLING/HYDROSTATICS COOLANT SIGHT GLASS'),
        ('root', 'QCW', 'COOLING/HYDROSTATICS COOLANT WATER RAIL'),
        ('root', 'QD', 'COOLING/HYDROSTATICS FAN DRIVE MOTORS'),
        ('root', 'QF', 'COOLING/HYDROSTATICS FANS (MECHANICAL PARTS)'),
        ('root', 'QH', 'COOLING/HYDROSTATICS HOSES'),
        ('root', 'QHC', 'COOLING/HYDROSTATICS HOSES  COOLANT'),
        ('root', 'QHH', 'COOLING/HYDROSTATICS HOSES  HYDROSTATIC'),
        ('root', 'QM', 'COOLING/HYDROSTATICS HYDROSTATIC'),
        ('root', 'QMA', 'COOLING/HYDROSTATICS HYDROSTATIC A10 PUMP (FANS)'),
        ('root', 'QMB', 'COOLING/HYDROSTATICS HYDROSTATIC A11 PUMP (ALTERNATOR)'),
        ('root', 'QMC', 'COOLING/HYDROSTATICS HYDROSTATIC PROPORTIONAL VALVE'),
        ('root', 'QMD', 'COOLING/HYDROSTATICS HYDROSTATIC FAN DRIVE SOLENOID'),
        ('root', 'QME', 'COOLING/HYDROSTATICS HYDROSTATIC SUCTION ISOLATOR'),
        ('root', 'QMF', 'COOLING/HYDROSTATICS HYDROSTATIC OIL LEAK'),
        ('root', 'QMG', 'COOLING/HYDROSTATICS HYDROSTATIC AUXILIARY DRIVE'),
        ('root', 'QMH', 'COOLING/HYDROSTATICS HYDROSTATIC HYDRO OIL LEVEL SENSOR'),
        ('root', 'QMJ', 'COOLING/HYDROSTATICS HYDROSTATIC IN FALLBACK'),
        ('root', 'QMK', 'COOLING/HYDROSTATICS HYDROSTATIC BY PASS VALVE'),
        ('root', 'QMN', 'COOLING/HYDROSTATICS HYDROSTATIC CONTROLLER'),
        ('root', 'QMO', 'COOLING/HYDROSTATICS HYDROSTATIC OIL CONTAMINATION'),
        ('root', 'QMP', 'COOLING/HYDROSTATICS HYDROSTATIC RAD FAN PUMP (15X)'),
        ('root', 'QMR', 'COOLING/HYDROSTATICS HYDROSTATIC RESET'),
        ('root', 'QMS', 'COOLING/HYDROSTATICS HYDROSTATIC DRS SOLENOID'),
        ('root', 'QMT', 'COOLING/HYDROSTATICS HYDROSTATIC TEMPERATURE SENSOR'),
        ('root', 'QMU', 'COOLING/HYDROSTATICS HYDROSTATIC ALTERNATOR MOTOR'),
        ('root', 'QMV', 'COOLING/HYDROSTATICS HYDROSTATIC VARIABLE DISPL PUMP'),
        ('root', 'QP', 'COOLING/HYDROSTATICS WATER PUMP'),
        ('root', 'QPA', 'COOLING/HYDROSTATICS WATER PUMP BEARING SEAL'),
        ('root', 'QPB', 'COOLING/HYDROSTATICS WATER PUMP IDLER ARM'),
        ('root', 'QPC', 'COOLING/HYDROSTATICS WATER PUMP BELT'),
        ('root', 'QR', 'COOLING/HYDROSTATICS RADIATORS'),
        ('root', 'QRA', 'COOLING/HYDROSTATICS RADIATORS  COOLANT RADIATOR'),
        ('root', 'QRB', 'COOLING/HYDROSTATICS RADIATORS  CHARGE AIR RADIATOR'),
        ('root', 'QRC', 'COOLING/HYDROSTATICS RADIATORS  HYDROSTATIC RADIATOR'),
        ('root', 'QRD', 'COOLING/HYDROSTATICS RADIATORS  COOLER GROUP'),
        ('root', 'QU', 'COOLING/HYDROSTATICS THERMOSTAT'),
        ('root', 'QV', 'COOLING/HYDROSTATICS AMOT VALVE'),
        ('root', 'QW', 'COOLING/HYDROSTATICS PIPEWORK'),
        ('root', 'TA', 'TRANSMISSION SENSORS'),
        ('root', 'TAA', 'TRANSMISSION SENSORS DIRECTION PROXIMITY SWITCHES'),
        ('root', 'TAB', 'TRANSMISSION SENSORS FREQUENCY TRANSDUCERS'),
        ('root', 'TAC', 'TRANSMISSION SENSORS TEMPERATURE SENSORS'),
        ('root', 'TAD', 'TRANSMISSION SENSORS PRESSURE SENSORS'),
        ('root', 'TAM', 'TRANSMISSION SENSORS MICROSWITCHES'),
        ('root', 'TB', 'TRANSMISSION OIL FILL'),
        ('root', 'TC', 'TRANSMISSION OIL LEAK'),
        ('root', 'TE', 'TRANSMISSION ELECTRICAL WIRING'),
        ('root', 'TEE', 'TRANSMISSION ELECTRICAL WIRING EP VALVE'),
        ('root', 'TF', 'TRANSMISSION FILTERS'),
        ('root', 'TG', 'TRANSMISSION GEARBOX'),
        ('root', 'TGA', 'TRANSMISSION GEARBOX  REVERSER SHAFT FAULT'),
        ('root', 'TGC', 'TRANSMISSION GEARBOX  CONTROL PISTON'),
        ('root', 'TGG', 'TRANSMISSION GEARBOX  GOVERNOR'),
        ('root', 'TGS', 'TRANSMISSION GEARBOX  STANDSTILL VALVE'),
        ('root', 'TH', 'TRANSMISSION HEAT EXCHANGER'),
        ('root', 'TS', 'TRANSMISSION SOLENOID PACK'),
        ('root', 'TU', 'TRANSMISSION TRANSMISSION CONTROLLER'),
        ('root', 'TW', 'TRANSMISSION PIPEWORK'),
        ('root', 'TX', 'TRANSMISSION TRANSMISSION AIR REGULATOR'),
        ('root', 'TZ', 'TRANSMISSION TRANSMISSION CONDEMNED'),
        ('root', 'ZA', 'CAUSE OUTSTANDING None'),
        ('root', 'ZB', 'NO ACTION REQUIRED None'),
        ('root', 'ZC', 'REPEAT DEFECT None');

    -- Insert symptom codes
    INSERT INTO #src_code (code_type, code_short, code_long)
    VALUES
        ('symptom', 'ADVERSE', 'ADVERSE OIL SAMPLE'),
        ('symptom', 'AECB TRIP', 'AECB TRIP'),
        ('symptom', 'AIR LEAK', 'AIR LEAK'),
        ('symptom', 'CLOP', 'CLOP'),
        ('symptom', 'COMP NOISY', 'COMPRESSOR NOISY'),
        ('symptom', 'COOL LEAK', 'COOLANT LEAK'),
        ('symptom', 'COOL PRESS', 'COOLANT SYSTEM PRESSURING'),
        ('symptom', 'CYL LEAK', 'CYLINDER HEAD LEAK'),
        ('symptom', 'D*CLOP', 'D*CLOP'),
        ('symptom', 'D*CO', 'D*CO'),
        ('symptom', 'D*LP', 'D*LP'),
        ('symptom', 'D*NR', 'D*NR'),
        ('symptom', 'D*RI', 'D*RI'),
        ('symptom', 'D*RTI', 'D*RTI'),
        ('symptom', 'D*TFL', 'D*TFL'),
        ('symptom', 'E*CB', 'E*CB'),
        ('symptom', 'E*CF', 'E*CF'),
        ('symptom', 'E*ELE', 'E*ELE'),
        ('symptom', 'E*FL', 'E*FL'),
        ('symptom', 'E*FLE', 'E*FLE'),
        ('symptom', 'E*FLG', 'E*FLG'),
        ('symptom', 'E*FLH', 'E*FLH'),
        ('symptom', 'E*FLT', 'E*FLT'),
        ('symptom', 'EHAB 180', 'EHAB 180 CODE'),
        ('symptom', 'ENG HUNT', 'ENGINE HUNTING'),
        ('symptom', 'ENG KNOCK', 'ENGINE KNOCKING'),
        ('symptom', 'ENG NOISY', 'ENGINE NOISY'),
        ('symptom', 'ENG RUN ON', 'ENGINE RUNNING ON'),
        ('symptom', 'ENG SMOKE', 'ENGINE SMOKING'),
        ('symptom', 'EXC COOL', 'EXCESS COOLANT'),
        ('symptom', 'EXHAUST', 'EXHAUST'),
        ('symptom', 'EXH SMOKE', 'EXHAUST SMOKING'),
        ('symptom', 'FANS RUN', 'FANS CONTINUALLY RUNNING'),
        ('symptom', 'FOUND EXM', 'FOUND ON EXAM'),
        ('symptom', 'FUEL LEAK', 'FUEL LEAK'),
        ('symptom', 'HEAVY BRE', 'HEAVY BREATHING'),
        ('symptom', 'HIGH OIL', 'HIGH OIL USAGE'),
        ('symptom', 'HYDRO LEAK', 'HYDRO OIL LEAK'),
        ('symptom', 'IFU FAULT', 'IFU FAULT CODES'),
        ('symptom', 'LOW AIR', 'LOW AIR'),
        ('symptom', 'LOW IDLE', 'LOW IDLE'),
        ('symptom', 'LOW OIL', 'LOW OIL'),
        ('symptom', 'LOW OIL P', 'LOW OIL PRESSURE'),
        ('symptom', 'OIL LEAK', 'OIL LEAK'),
        ('symptom', 'SLOW AIR', 'SLOW MAKING AIR'),
        ('symptom', 'T*LOP', 'T*LOP'),
        ('symptom', 'T*NR', 'T*NR'),
        ('symptom', 'TRANS LEAK', 'TRANSMISSION OIL LEAK'),
        ('symptom', 'TRANS FLT', 'TRANSMISSION FAULT'),
        ('symptom', 'TURBO', 'TURBO');

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                c.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        COALESCE(c.code_type, '') + '|' +
                        COALESCE(c.code_short, '') + '|' +
                        COALESCE(c.code_long, '')
                    )
                ) AS row_hash
            FROM dbo.dim_code AS c
        )
        MERGE dbo.dim_code AS tgt
        USING #src_code AS src
            ON tgt.code_type = src.code_type
           AND tgt.code_short = src.code_short

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.code_type = tgt.code_type
                   AND th.code_short = tgt.code_short) <> src.row_hash
        THEN UPDATE SET
            tgt.code_long = src.code_long

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (code_type, code_short, code_long)
            VALUES (src.code_type, src.code_short, src.code_long)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_code') IS NOT NULL
        DROP TABLE #src_code;
END;
