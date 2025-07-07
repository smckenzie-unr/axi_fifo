library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity AXI_FIFO is
    generic(C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
            C_AXI_ADDRESS_WIDTH: integer range 4 to 128 := 5);
    port(S_AXI_ACLK: in std_logic;
         S_AXI_ARESETN: in std_logic;
         S_AXI_AWADDR: in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
         S_AXI_AWPROT: in std_logic_vector(2 downto 0);
         S_AXI_AWVALID: in std_logic;
         S_AXI_AWREADY: out std_logic;
         S_AXI_WDATA: in std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
         S_AXI_WSTRB: in std_logic_vector((C_AXI_DATA_WIDTH / 8) - 1 downto 0);
         S_AXI_WVALID: in std_logic;
         S_AXI_WREADY: out std_logic;
         S_AXI_BRESP: out std_logic_vector(1 downto 0);
         S_AXI_BVALID: out std_logic;
         S_AXI_BREADY: in std_logic;
         S_AXI_ARADDR: in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
         S_AXI_ARPROT: in std_logic_vector(2 downto 0);
         S_AXI_ARVALID: in std_logic;
         S_AXI_ARREADY: out std_logic;
         S_AXI_RDATA: out std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
         S_AXI_RRESP: out std_logic_vector(1 downto 0);
         S_AXI_RVALID: out std_logic;
         S_AXI_RREADY: in std_logic);
end AXI_FIFO;

architecture synth_logic of AXI_FIFO is
    constant C_NUM_REGISTERS: integer range 1 to 1024 := 5;
    constant READ_CONTROL_REGISTER: integer := 0;
    constant READ_DATA_REGISTER: integer := 1; 
    constant WRITE_CONTROL_REGISTER: integer := 2;
    constant WRITE_DATA_REGISTER: integer := 3;
    constant FIFO_STATUS_REGISTER: integer := 4;

    component axi4_lite_slave_if is
        generic(C_AXI_DATA_WIDTH: integer range 32 to 128;
                C_AXI_ADDRESS_WIDTH: integer range 4 to 128;
                C_NUM_REGISTERS: integer range 1 to 1024);
        port(S_AXI_ACLK: in std_logic;
            S_AXI_ARESETN: in std_logic;
            S_AXI_AWADDR: in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
            S_AXI_AWPROT: in std_logic_vector(2 downto 0);
            S_AXI_AWVALID: in std_logic;
            S_AXI_AWREADY: out std_logic;
            S_AXI_WVALID: in std_logic;
            S_AXI_WREADY: out std_logic;
            S_AXI_BRESP: out std_logic_vector(1 downto 0);
            S_AXI_BVALID: out std_logic;
            S_AXI_BREADY: in std_logic;
            S_AXI_ARADDR: in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
            S_AXI_ARPROT: in std_logic_vector(2 downto 0);
            S_AXI_ARVALID: in std_logic;
            S_AXI_ARREADY: out std_logic;
            S_AXI_RRESP: out std_logic_vector(1 downto 0);
            S_AXI_RVALID: out std_logic;
            S_AXI_RREADY: in std_logic;

            REGISTER_WR: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0);
            REGISTER_RD: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0));
    end component;


    type register_types is (CNTRL_REG, STATUS_REG);
    type slv_array is array (0 to C_NUM_REGISTERS - 1) of std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
    type register_defs is array(0 to C_NUM_REGISTERS - 1) of register_types;

    signal reg_check: register_defs := (FIFO_STATUS_REGISTER => STATUS_REG, 
                                        READ_DATA_REGISTER => STATUS_REG,
                                        others => CNTRL_REG);
    signal registers: slv_array := (others => (others => '0'));
    signal reg_write: std_logic_vector(C_NUM_REGISTERS - 1 downto 0) := (others => '0');
    signal reg_read: std_logic_vector(C_NUM_REGISTERS - 1 downto 0) := (others => '0');
    signal strobe_read: std_logic := '0';
    signal strobe_write: std_logic := '0';

    signal axi_rdata: std_logic_vector(S_AXI_RDATA'range) := (others => '0');
    signal fifo_reset: std_logic := '0';

    alias read_cntrl_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(READ_CONTROL_REGISTER);
    alias read_data_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(READ_DATA_REGISTER);

    alias write_cntrl_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(WRITE_CONTROL_REGISTER);
    alias write_data_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(WRITE_DATA_REGISTER);

    alias fifo_status_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(FIFO_STATUS_REGISTER);
begin

    S_AXI_RDATA <= axi_rdata;
    fifo_reset <= not S_AXI_ARESETN;

    axi_interface: axi4_lite_slave_if generic map(C_AXI_DATA_WIDTH => C_AXI_DATA_WIDTH,
                                                  C_AXI_ADDRESS_WIDTH => C_AXI_ADDRESS_WIDTH,
                                                  C_NUM_REGISTERS => C_NUM_REGISTERS)
                                      port map(S_AXI_ACLK => S_AXI_ACLK,
                                               S_AXI_ARESETN => S_AXI_ARESETN,
                                               S_AXI_AWADDR => S_AXI_AWADDR,
                                               S_AXI_AWPROT => S_AXI_AWPROT,
                                               S_AXI_AWVALID => S_AXI_AWVALID,
                                               S_AXI_AWREADY => S_AXI_AWREADY,
                                               S_AXI_WVALID => S_AXI_WVALID,
                                               S_AXI_WREADY => S_AXI_WREADY,
                                               S_AXI_BRESP => S_AXI_BRESP,
                                               S_AXI_BVALID => S_AXI_BVALID,
                                               S_AXI_BREADY => S_AXI_BREADY,
                                               S_AXI_ARADDR => S_AXI_ARADDR,
                                               S_AXI_ARPROT => S_AXI_ARPROT,
                                               S_AXI_ARVALID => S_AXI_ARVALID,
                                               S_AXI_ARREADY => S_AXI_ARREADY,
                                               S_AXI_RRESP => S_AXI_RRESP,
                                               S_AXI_RVALID => S_AXI_RVALID,
                                               S_AXI_RREADY => S_AXI_RREADY,
                                               REGISTER_WR => reg_write,
                                               REGISTER_RD => reg_read);

    FIFO18E2_inst: FIFO18E2 generic map (CASCADE_ORDER => "NONE",            -- FIRST, LAST, MIDDLE, NONE, PARALLEL
                                         CLOCK_DOMAINS => "COMMON",     -- COMMON, INDEPENDENT
                                         FIRST_WORD_FALL_THROUGH => "FALSE", -- FALSE, TRUE
                                         INIT => X"000000000",               -- Initial values on output port
                                         PROG_EMPTY_THRESH => 256,           -- Programmable Empty Threshold
                                         PROG_FULL_THRESH => 256,            -- Programmable Full Threshold
                                         -- Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
                                         IS_RDCLK_INVERTED => '0',           -- Optional inversion for RDCLK
                                         IS_RDEN_INVERTED => '0',            -- Optional inversion for RDEN
                                         IS_RSTREG_INVERTED => '0',          -- Optional inversion for RSTREG
                                         IS_RST_INVERTED => '0',             -- Optional inversion for RST
                                         IS_WRCLK_INVERTED => '0',           -- Optional inversion for WRCLK
                                         IS_WREN_INVERTED => '0',            -- Optional inversion for WREN
                                         RDCOUNT_TYPE => "RAW_PNTR",         -- EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
                                         READ_WIDTH => 36,                    -- 18-9?????
                                         REGISTER_MODE => "UNREGISTERED",    -- DO_PIPELINED, REGISTERED, UNREGISTERED
                                         RSTREG_PRIORITY => "RSTREG",        -- REGCE, RSTREG
                                         SLEEP_ASYNC => "FALSE",             -- FALSE, TRUE
                                         SRVAL => X"000000000",              -- SET/reset value of the FIFO outputs
                                         WRCOUNT_TYPE => "RAW_PNTR",         -- EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
                                         WRITE_WIDTH => 36)                  -- 18-9?????  
                            port map (CASDOUT => open,                       -- 32-bit output: Data cascade output bus
                                      CASDOUTP => open,                      -- 4-bit output: Parity data cascade output bus
                                      CASNXTEMPTY => open,                   -- 1-bit output: Cascade next empty
                                      CASPRVRDEN => open,                    -- 1-bit output: Cascade previous read enable
                                      -- Read Data outputs: Read output data
                                      DOUT => read_data_reg,                 -- 32-bit output: FIFO data output bus
                                      DOUTP => open,                         -- 4-bit output: FIFO parity output bus.
                                      -- Status outputs: Flags and other FIFO status outputs
                                      EMPTY => fifo_status_reg(0),           -- 1-bit output: Empty
                                      FULL => fifo_status_reg(1),            -- 1-bit output: Full
                                      PROGEMPTY => fifo_status_reg(2),       -- 1-bit output: Programmable empty
                                      PROGFULL => fifo_status_reg(3),        -- 1-bit output: Programmable full
                                      RDCOUNT => open,                       -- 13-bit output: Read count
                                      RDERR => fifo_status_reg(4),           -- 1-bit output: Read error
                                      RDRSTBUSY => fifo_status_reg(5),       -- 1-bit output: Reset busy (sync to RDCLK)
                                      WRCOUNT => open,                       -- 13-bit output: Write count
                                      WRERR => fifo_status_reg(6),           -- 1-bit output: Write Error
                                      WRRSTBUSY => fifo_status_reg(7),       -- 1-bit output: Reset busy (sync to WRCLK)
                                      -- Cascade Signals inputs: Multi-FIFO cascade signals
                                      CASDIN => (others => '0'),             -- 32-bit input: Data cascade input bus
                                      CASDINP => (others => '0'),            -- 4-bit input: Parity data cascade input bus
                                      CASDOMUX => '0',                       -- 1-bit input: Cascade MUX select
                                      CASDOMUXEN => '0',                     -- 1-bit input: Enable for cascade MUX select
                                      CASNXTRDEN => '0',                     -- 1-bit input: Cascade next read enable
                                      CASOREGIMUX => '0',                    -- 1-bit input: Cascade output MUX select
                                      CASOREGIMUXEN => '0',                  -- 1-bit input: Cascade output MUX select enable
                                      CASPRVEMPTY => '0',                    -- 1-bit input: Cascade previous empty
                                      -- Read Control Signals inputs: Read clock, enable and reset input signals
                                      RDCLK => S_AXI_ACLK,                   -- 1-bit input: Read clock
                                      RDEN => read_cntrl_reg(0),             -- 1-bit input: Read enable
                                      REGCE => read_cntrl_reg(1),            -- 1-bit input: Output register clock enable
                                      RSTREG => read_cntrl_reg(2),           -- 1-bit input: Output register reset
                                      SLEEP => read_cntrl_reg(3),            -- 1-bit input: Sleep Mode
                                      -- Write Control Signals inputs: Write clock and enable input signals
                                      RST => fifo_reset,                     -- 1-bit input: Reset
                                      WRCLK => S_AXI_ACLK,                   -- 1-bit input: Write clock
                                      WREN => write_cntrl_reg(0),            -- 1-bit input: Write enable
                                      -- Write Data inputs: Write input data
                                      DIN => write_data_reg,                 -- 32-bit input: FIFO data input bus
                                      DINP => (others => '0'));              -- 4-bit input: FIFO parity input bus
    
    
    read_reg_proc: process(S_AXI_ACLK) is
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(S_AXI_ARESETN = '0') then
                strobe_read <= '0';
                axi_rdata <= (others => '0');
            else
                strobe_read <= or_reduce(reg_read);
                for idx in reg_read'range loop
                    if(reg_read(idx) = '1' and strobe_read = '0') then
                        axi_rdata <= registers(idx);
                    end if;
                end loop;
            end if;
        end if;
    end process read_reg_proc;

    write_reg_proc: process(S_AXI_ACLK) is
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(S_AXI_ARESETN = '0') then
                strobe_write <= '0';
            else
                strobe_write <= or_reduce(reg_write);
                for idx in reg_write'range loop
                    if(reg_write(idx) = '1' and strobe_write = '0') then
                        if(reg_check(idx) = CNTRL_REG) then
                            for byte_index in 0 to ((C_AXI_DATA_WIDTH / 8) - 1) loop
                                if(S_AXI_WSTRB(byte_index) = '1') then
                                    registers(idx)(byte_index * 8 + 7 downto byte_index * 8) <= S_AXI_WDATA(byte_index * 8 + 7 downto byte_index * 8);
                                end if;
                            end loop;
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process write_reg_proc;
end synth_logic;
