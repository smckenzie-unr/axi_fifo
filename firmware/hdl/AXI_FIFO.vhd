library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity AXI_FIFO is
    generic(C_AXI_ADDRESS_BUS_WIDTH:)
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

begin


end synth_logic;
