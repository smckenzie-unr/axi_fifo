library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_testbench is
    generic(C_AXI_ADDRESS_WIDTH: integer range 1 to 128 := 10;
            C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
            C_NUM_REGISTERS: integer range 1 to 1024 := 256);
end axi_testbench;

architecture behavioral of axi_testbench is
    signal S_AXI_ACLK: std_logic := '0';
    signal S_AXI_ARESETN: std_logic := '0';
    signal S_AXI_AWADDR: std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_AWPROT: std_logic_vector(2 downto 0) := (others => '0');
    signal S_AXI_AWVALID: std_logic := '0';
    signal S_AXI_AWREADY: std_logic := '0';
    signal S_AXI_WDATA: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_WSTRB: std_logic_vector((C_AXI_DATA_WIDTH / 8) - 1 downto 0) := (others => '0');
    signal S_AXI_WVALID: std_logic := '0';
    signal S_AXI_WREADY: std_logic := '0';
    signal S_AXI_BRESP: std_logic_vector(1 downto 0) := (others => '0');
    signal S_AXI_BVALID: std_logic := '0';
    signal S_AXI_BREADY: std_logic := '0';
    signal S_AXI_ARADDR: std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_ARPROT: std_logic_vector(2 downto 0) := (others => '0');
    signal S_AXI_ARVALID: std_logic := '0';
    signal S_AXI_ARREADY: std_logic := '0';
    signal S_AXI_RDATA: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_RRESP: std_logic_vector(1 downto 0) := (others => '0');
    signal S_AXI_RVALID: std_logic := '0';
    signal S_AXI_RREADY: std_logic := '0';
begin
    S_AXI_ACLK <= not S_AXI_ACLK after 4 ns;
    S_AXI_ARESETN <= '1' after 1 us;

    MUT: entity work.AXI_FIFO generic map(C_AXI_ADDRESS_WIDTH => C_AXI_ADDRESS_WIDTH,
                                          C_AXI_DATA_WIDTH => C_AXI_DATA_WIDTH,
                                          C_NUM_REGISTERS => C_NUM_REGISTERS)
                              port map(S_AXI_ACLK => S_AXI_ACLK,
                                       S_AXI_ARESETN => S_AXI_ARESETN,
                                       S_AXI_AWADDR => S_AXI_AWADDR,
                                       S_AXI_AWPROT => S_AXI_AWPROT,
                                       S_AXI_AWVALID => S_AXI_AWVALID,
                                       S_AXI_AWREADY => S_AXI_AWREADY,
                                       S_AXI_WDATA => S_AXI_WDATA,
                                       S_AXI_WSTRB => S_AXI_WSTRB,
                                       S_AXI_WVALID => S_AXI_WVALID,
                                       S_AXI_WREADY => S_AXI_WREADY,
                                       S_AXI_BRESP => S_AXI_BRESP,
                                       S_AXI_BVALID => S_AXI_BVALID,
                                       S_AXI_BREADY => S_AXI_BREADY,
                                       S_AXI_ARADDR => S_AXI_ARADDR,
                                       S_AXI_ARPROT => S_AXI_ARPROT,
                                       S_AXI_ARVALID => S_AXI_ARVALID,
                                       S_AXI_ARREADY => S_AXI_ARREADY,
                                       S_AXI_RDATA => S_AXI_RDATA,
                                       S_AXI_RRESP => S_AXI_RRESP,
                                       S_AXI_RVALID => S_AXI_RVALID,
                                       S_AXI_RREADY => S_AXI_RREADY);

    -- stimulus_proc: process
    --     type state_type is (idle, read_4, wait_4, read_8, wait_8, read_C, wait_C, done);
    --     variable state : state_type := idle;
    --     variable cycle_cnt : integer := 0;
    --     variable rready_asserted : boolean := false;
    -- begin
    --     wait until rising_edge(S_AXI_ACLK);
    --     while true loop
    --         -- Deassert S_AXI_RREADY after one clock if it was asserted
    --         if rready_asserted then
    --             S_AXI_RREADY <= '0';
    --             rready_asserted := false;
    --         end if;

    --         case state is
    --             when idle =>
    --                 if S_AXI_ARESETN = '1' then
    --                     cycle_cnt := 0;
    --                     state := read_4;
    --                 end if;

    --             when read_4 =>
    --                 S_AXI_ARADDR  <= x"4";
    --                 S_AXI_ARVALID <= '1';
    --                 if S_AXI_ARREADY = '1' then
    --                     S_AXI_ARVALID <= '0';
    --                     state := wait_4;
    --                 end if;

    --             when wait_4 =>
    --                 if S_AXI_RVALID = '1' then
    --                     S_AXI_RREADY <= '1';
    --                     rready_asserted := true;
    --                     cycle_cnt := 0;
    --                     state := read_8;
    --                 end if;

    --             when read_8 =>
    --                 if cycle_cnt < 125 then
    --                     cycle_cnt := cycle_cnt + 1;
    --                 else
    --                     S_AXI_ARADDR  <= x"8";
    --                     S_AXI_ARVALID <= '1';
    --                     if S_AXI_ARREADY = '1' then
    --                         S_AXI_ARVALID <= '0';
    --                         state := wait_8;
    --                     end if;
    --                 end if;

    --             when wait_8 =>
    --                 if S_AXI_RVALID = '1' then
    --                     S_AXI_RREADY <= '1';
    --                     rready_asserted := true;
    --                     cycle_cnt := 0;
    --                     state := read_C;
    --                 end if;

    --             when read_C =>
    --                 if cycle_cnt < 125 then
    --                     cycle_cnt := cycle_cnt + 1;
    --                 else
    --                     S_AXI_ARADDR  <= x"C";
    --                     S_AXI_ARVALID <= '1';
    --                     if S_AXI_ARREADY = '1' then
    --                         S_AXI_ARVALID <= '0';
    --                         state := wait_C;
    --                     end if;
    --                 end if;

    --             when wait_C =>
    --                 if S_AXI_RVALID = '1' then
    --                     S_AXI_RREADY <= '1';
    --                     rready_asserted := true;
    --                     state := done;
    --                 end if;

    --             when done =>
    --                 wait;
    --         end case;
    --         wait until rising_edge(S_AXI_ACLK);
    --     end loop;
    -- end process stimulus_proc;

    -- S_AXI_ARVALID <= '1' after 1.204 us,
    --                  '0' after 1.220 us;
    -- S_AXI_ARADDR <= X"C" after 1.204 us,
    --                 X"0" after 1.220 us;
    -- S_AXI_RREADY <= '1' after 1.228 us,
    --                 '0' after 1.236 us;


    S_AXI_AWVALID <= '1' after 1.100 us,
                     '0' after 1.116 us;
    S_AXI_AWADDR <= "0000000100" after 1.100 us,
                    "0000000000" after 1.116 us;
    S_AXI_WSTRB <= "1111"; -- after 1.110 us,
                   --"0000" after 1.120 us;
    S_AXI_WDATA <= X"BADBABE5" after 1.108 us,
                   X"00000000" after 1.132 us;
    S_AXI_WVALID <= '1' after 1.116 us,
                    '0' after 1.132 us;
    S_AXI_BREADY <= '1' after 1.140 us,
                    '0' after 1.148 us;
    S_AXI_ARVALID <= '1' after 1.204 us,
                     '0' after 1.220 us;
    S_AXI_ARADDR <= "0000000100" after 1.204 us,
                    "0000000000" after 1.220 us;
    S_AXI_RREADY <= '1' after 1.228 us,
                    '0' after 1.236 us;

end behavioral;
