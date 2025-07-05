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
    constant C_NUM_REGISTERS: integer range 1 to 1024 := 6;
    constant READ_CONTROL_REGISTER: integer := 0;
    constant READ_DATA_REGISTER: integer := 1; 
    constant READ_STATUS_REGISTER: integer := 2;
    constant WRITE_CONTROL_REGISTER: integer := 3;
    constant WRITE_DATA_REGISTER: integer := 4;
    constant WRITE_STATUS_REGISTER: integer := 5;
    -- component axi4_lite_slave_if is
    --     generic(C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
    --             C_AXI_ADDRESS_WIDTH: integer range 4 to 128 := 4;
    --             C_NUM_REGISTERS: integer range 1 to 1024 := 4);
    --     port(S_AXI_ACLK: in std_logic;
    --          S_AXI_ARESETN: in std_logic;
    --          S_AXI_AWADDR: in std_logic_vector(integer(ceil(log2(real(C_NUM_REGISTERS)))) + 1 downto 0);
    --          S_AXI_AWPROT: in std_logic_vector(2 downto 0);
    --          S_AXI_AWVALID: in std_logic;
    --          S_AXI_AWREADY: out std_logic;
    --          S_AXI_WVALID: in std_logic;
    --          S_AXI_WREADY: out std_logic;
    --          S_AXI_BRESP: out std_logic_vector(1 downto 0);
    --          S_AXI_BVALID: out std_logic;
    --          S_AXI_BREADY: in std_logic;
    --          S_AXI_ARADDR: in std_logic_vector(integer(ceil(log2(real(C_NUM_REGISTERS)))) + 1 downto 0);
    --          S_AXI_ARPROT: in std_logic_vector(2 downto 0);
    --          S_AXI_ARVALID: in std_logic;
    --          S_AXI_ARREADY: out std_logic;
    --          S_AXI_RRESP: out std_logic_vector(1 downto 0);
    --          S_AXI_RVALID: out std_logic;
    --          S_AXI_RREADY: in std_logic;

    --          REGISTER_WR: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0);
    --          REGISTER_RD: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0));
    -- end component;

    type register_types is (CNTRL_REG, STATUS_REG);
    type slv_array is array (0 to C_NUM_REGISTERS - 1) of std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
    type register_defs is array(0 to C_NUM_REGISTERS - 1) of register_types;

    signal reg_check: register_defs := (READ_STATUS_REGISTER => STATUS_REG, 
                                        WRITE_STATUS_REGISTER => STATUS_REG, 
                                        others => CNTRL_REG);
    signal registers: slv_array := (others => (others => '0'));
    signal reg_write: std_logic_vector(C_NUM_REGISTERS - 1 downto 0) := (others => '0');
    signal reg_read: std_logic_vector(C_NUM_REGISTERS - 1 downto 0) := (others => '0');
    signal strobe_read: std_logic := '0';
    signal strobe_write: std_logic := '0';

    signal axi_rdata: std_logic_vector(S_AXI_RDATA'range) := (others => '0');

    alias read_cntrl_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(0);
    alias read_data_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(1);

    alias write_cntrl_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(2);
    alias write_data_reg: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) is registers(3);
begin

    S_AXI_RDATA <= axi_rdata;
    axi_interface: entity work.axi4_lite_slave_if generic map(C_AXI_DATA_WIDTH => C_AXI_DATA_WIDTH,
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

    -- FIFO18E2_inst: entity unisim.FIFO18E2 generic map(CLOCK_DOMAINS => "COMMON",
    --                                                   FIRST_WORD_FALL_THROUGH => true,
    --                                                   READ_WIDTH => 36,
    --                                                   WRITE_WIDTH => 36)
    --                                       port map(RDCLK => S_AXI_ACLK,
    --                                                WRCLK => S_AXI_ACLK,
    --                                                RST => not S_AXI_ARESETN,
    --                                                )
    
    
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




    -- FIFO18E2_inst: entity unisim.FIFO18E2
    --     generic map (
    --         CLOCK_DOMAINS          => "COMMON",
    --         FIRST_WORD_FALL_THROUGH=> true,
    --         READ_WIDTH             => 36,
    --         WRITE_WIDTH            => 36
    --     )
    --     port map (
    --         -- Clocks and resets
    --         RDCLK      => S_AXI_ACLK,
    --         WRCLK      => S_AXI_ACLK,
    --         RST        => fifo_rst,

    --         -- Write port
    --         DIN        => fifo_din,
    --         WRCLK_EN   => '1',         -- Always enabled
    --         WREN       => fifo_wr_en,
    --         FULL       => fifo_full,
    --         WRCOUNT    => open,        -- Optional: connect if needed
    --         WRERR      => open,        -- Optional: connect if needed

    --         -- Read port
    --         DOUT       => fifo_dout,
    --         RDCLK_EN   => '1',         -- Always enabled
    --         RDEN       => fifo_rd_en,
    --         EMPTY      => fifo_empty,
    --         RDCOUNT    => open,        -- Optional: connect if needed
    --         RDERR      => open,        -- Optional: connect if needed

    --         -- ECC/Parity (not used here)
    --         INJECTDBITERR => '0',
    --         INJECTSBITERR => '0',
    --         DBITERR       => open,
    --         SBITERR       => open,

    --         -- Unused ports
    --         SLEEP      => '0',
    --         PROG_FULL  => open,
    --         PROG_EMPTY => open
    --     );