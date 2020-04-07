--Things to watch for:
--Timing - is everything timed right
--Wait commands - will inputs eventually become the values specified
--Active-high and active-low signals - do we accidentally "assert" active-low signals with '1' or vice versa?

--I'm too scared to test this.

--Name: RAMs
--Date: Today
--Description: Starting VHDL code for peripheral

LIBRARY IEEE;
LIBRARY ALTERA_MF;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY IO_SRAM IS
	PORT(
		IO_WRITE		: IN    STD_LOGIC;
		SRAM_ADHI_EN    : IN    STD_LOGIC;
		SRAM_ADLOW_EN	: IN    STD_LOGIC;
		SRAM_DATA_EN	: IN	STD_LOGIC;		
		IO_DATA    		: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		SRAM_ADDR		: OUT	STD_LOGIC_VECTOR(17 DOWNTO 0);
		SRAM_OE_N		: OUT	STD_LOGIC := '1';
		SRAM_DQ			: INOUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		SRAM_WE_N		: OUT	STD_LOGIC := '1';
		SRAM_UB_N		: OUT	STD_LOGIC;
		SRAM_LB_N		: OUT	STD_LOGIC;
		SRAM_CE_N		: OUT	STD_LOGIC
	);
END IO_SRAM;


ARCHITECTURE a OF IO_SRAM IS

	SIGNAL ADLOW	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ADHI		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL READ_EN	: STD_LOGIC; -- Read from SRAM
	SIGNAL WRITE_EN	: STD_LOGIC; -- Write to SRAM

BEGIN
	
	--Handle sending data from SCOMP to SRAM
	IO_BUS: LPM_BUSTRI
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => IO_DATA,
		enabledt => WRITE_EN,
		tridata  => SRAM_DQ
	);
	
	--Might have to make new signals to read and write IO_DATA, SRAM_DQ
	
	--Set high part of address
	SET_ADHI : PROCESS (SRAM_ADHI_EN)
	BEGIN
		IF RISING_EDGE(SRAM_ADHI_EN) AND IO_WRITE = '1' THEN
			ADHI <= IO_DATA(1 DOWNTO 0);
		END IF;
	END PROCESS;
	
	--Set low part of address
	SET_ADLOW : PROCESS (SRAM_ADLOW_EN)
	BEGIN
		IF RISING_EDGE(SRAM_ADLOW_EN) AND IO_WRITE = '1' THEN
			ADLOW <= IO_DATA;
		END IF;
	END PROCESS;
	
	--Handle incoming and outgoing data
	IO_SRAM_DATA : PROCESS
	BEGIN
		IF RISING_EDGE(SRAM_DATA_EN) THEN
			IF IO_WRITE = '0' THEN --Reading data from SRAM
				WAIT UNTIL IO_DATA = "ZZZZZZZZZZZZZZZZ";
				READ_EN <= '1';
				WAIT UNTIL SRAM_DATA_EN = '0';
				READ_EN <= '0';
			ELSE -- Writing data to SRAM
				SRAM_WE_N <= '0';
				WAIT UNTIL SRAM_DQ = "ZZZZZZZZZZZZZZZZ";
				WRITE_EN <= '1';
				WAIT UNTIL SRAM_DATA_EN = '0';
				SRAM_WE_N <= '1';
				WAIT UNTIL IO_WRITE = '0'; --Potential timing problem?
				WRITE_EN <= 0;	
			END IF;
		END IF;
	END PROCESS;

	--Set SRAM address
	SRAM_ADDR <= ADHI & ADLOW;
	
	--OE_N can be asserted at the same time as READ_EN
	SRAM_OE_N <= NOT(READ_EN);
	
	--This can't happen because writing to SRAM stops before SCOMP stops writing
	--SRAM_WE_N <= WRITE_EN;
	
	SRAM_UB_N <= '0';
	SRAM_LB_N <= '0';
	SRAM_CE_N <= '0';
		
END a;
