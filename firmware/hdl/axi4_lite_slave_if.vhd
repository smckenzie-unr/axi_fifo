library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi4_lite_slave_if is
    generic(C_AXI_ADDRESS_WIDTH: integer range 1 to 128 := 4;
            C_AXI_DATA_WIDTH: integer range 32 to 128 := 32);
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
         S_AXI_RREADY: out std_logic;
         
         READ_REG_STROBE: out std_logic;
         READ_REG_ADDRESS: out std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
         READ_REG_DATA: in std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
         WRITE_REG_STROBE: out std_logic;
         WRITE_REG_ADDRESS: out std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
         WRITE_REG_DATA: out std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0));
end axi4_lite_slave_if;

architecture synth_logic of axi4_lite_slave_if is
    type read_statemachine_type is (IDLE, ADDRESS_LATCH, DATA_OUT);
    type write_statemachine_type is (IDLE, ADDRESS_LATCH, DATA_IN, RESP_OUT);
begin


end synth_logic;
