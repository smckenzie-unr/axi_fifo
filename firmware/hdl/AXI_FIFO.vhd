library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity AXI_FIFO is
    generic(C_AXI_ADDRESS_WIDTH: integer range 1 to 128 := 4;
            C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
            C_NUM_REGISTERS: integer range 1 to 1024 := 4);
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
         S_AXI_RREADY: out std_logic);
end AXI_FIFO;

architecture synth_logic of AXI_FIFO is
    component axi4_lite_slave_if is
        generic(C_AXI_ADDRESS_WIDTH: integer range 1 to 128 := 4;
                C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
                C_NUM_REGISTERS: integer range 1 to 1024 := 4);
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
             S_AXI_RREADY: out std_logic;

             REGISTER_WR: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0);
             REGISTER_RD: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0));
    end component;

    type slv_array is array (0 to C_NUM_REGISTERS - 1) of std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
    signal registers: slv_array := (others => (others => '0'));
    signal reg_write: std_logic_vector(C_NUM_REGISTERS - 1 downto 0) := (others => '0');
    signal reg_read: std_logic_vector(C_NUM_REGISTERS - 1 downto 0) := (others => '0');
begin

    axi_interface : axi4_lite_slave_if generic map(C_AXI_ADDRESS_WIDTH => C_AXI_ADDRESS_WIDTH,
                                                   C_AXI_DATA_WIDTH => C_AXI_DATA_WIDTH,
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

    read_reg_proc: process(S_AXI_ACLK) is
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(S_AXI_ARESETN = '0') then
                S_AXI_RDATA <= (others => '0');
            else
                for idx in 0 to C_NUM_REGISTERS - 1 loop
                    if(reg_read(idx) = '1') then
                        S_AXI_RDATA <= registers(idx);
                    end if;
                end loop;
            end if;
        end if;
    end process;

end synth_logic;
