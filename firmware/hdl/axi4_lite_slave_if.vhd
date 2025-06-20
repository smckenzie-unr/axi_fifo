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
         READ_REG_ADDRESS: out unsigned(S_AXI_ARADDR'range);
         READ_REG_DATA: in std_logic_vector(S_AXI_RDATA'range);
         WRITE_REG_STROBE: out std_logic;
         WRITE_REG_ADDRESS: out unsigned(S_AXI_AWADDR'range);
         WRITE_REG_DATA: out std_logic_vector(S_AXI_WDATA'range));
end axi4_lite_slave_if;

architecture synth_logic of axi4_lite_slave_if is
    type read_statemachine_type is (IDLE, ADDRESS_LATCH, DATA_OUT);
    type write_statemachine_type is (IDLE, ADDRESS_LATCH, DATA_IN, RESP_OUT);

    signal read_cstate: read_statemachine_type := IDLE;
    signal axi_arready: std_logic := '0';
    signal read_strobe: std_logic := '0';
    signal read_address: unsigned(READ_REG_ADDRESS'range) := (others => '0');
begin
    S_AXI_ARREADY <= axi_arready;
    READ_REG_STROBE <= read_strobe;
    READ_REG_ADDRESS <= read_address;

    read_process: process(S_AXI_ACLK) is
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(S_AXI_ARESETN = '0') then
                axi_arready <= '0';
                read_strobe <= '0';
                read_address <= (others => '0');
                read_cstate <= IDLE;
            else
                case read_cstate is
                    when IDLE =>
                        if(S_AXI_ARVALID = '1') then
                            read_cstate <= ADDRESS_LATCH;
                        else
                            read_cstate <= IDLE;
                        end if;
                    when ADDRESS_LATCH =>
                        axi_arready <= '1';
                        read_strobe <= '1';
                        read_address <= unsigned(S_AXI_ARADDR);
                        read_cstate <= DATA_OUT;
                    when DATA_OUT =>
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process read_process;

end synth_logic;
