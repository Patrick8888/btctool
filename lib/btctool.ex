defmodule BtcTool do
  @moduledoc """
  Bitcoin utils related to Elliptic curve cryptography (ECC) algorithms
  used in bitcoin to create addresses or public keys from private keys,
  brainwallets, WIFs, etc.
  """

  alias BtcTool.PrivKey

  # Min-max value for secp256k1 ECC. More info at:
  # https://bitcoin.stackexchange.com/questions/1389#answer-1715
  @ecc_min "0000000000000000000000000000000000000000000000000000000000000000" |> Base.decode16!()
  @ecc_max "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140" |> Base.decode16!()

  @typedoc """
  Wallet Import Format including the base58check containing the private
  key.

  WIF will be a base58check string of 51 characters (408 bits) if user
  want to use uncompressed public keys in the bitcoin addresses or 52
  characters (416 bits) if want to use compressed public keys.

  Metadata like `network` or `compressed` can also be deducted from the
  WIP string, but make them visible anyway here:
   - `network`. Which is instended to be used on.
   - `compressed`. Which state if a compressed public key will be used
  """
  @type wif_type :: %{wif: <<_::408>> | <<_::416>>, network: :testnet | :mainnet, compressed: boolean }

  @doc """
  Create Wallet Import Format (WIF) private key from raw private key.
  A raw private key can be presented by a binary of 32 bytes or in
  64 hexadecimal characters (0-9a-fA-F)

  It assumes you want the compressed WIF version by default. That way
  you are signalling that the bitcoin address which should be used when
  imported into a wallet will be also compressed.

  ## Options
    - `compressed` - Generate a WIF which signals that a compressed
      public key should be used if `true`. Deafault is `true`.
    - `network` - Specifies the network is this private key intended to
      be used on. Can be `:mainnet` or `:testnet`. Default is `:mainnet`.
    - `case` - Specifies the character case to accept when decoding.
      Valid values are: `:upper`, `:lower`, `:mixed`.
      Only useful when the raw private key is passed in hex format.
      Default is `:mixed`

  ## Examples

      iex> hexprivkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
      iex> binprivkey = hexprivkey |> Base.decode16!()
      <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>
      iex> privkey_to_wif(hexprivkey)
      {:ok, %{
        wif: "KwFvTne98E1t3mTNAr8pKx67eUzFJWdSNPqPSfxMEtrueW7PcQzL",
        compressed: true,
        network: :mainnet
      }}
      iex> privkey_to_wif(binprivkey)
      {:ok, %{
        wif: "KwFvTne98E1t3mTNAr8pKx67eUzFJWdSNPqPSfxMEtrueW7PcQzL",
        compressed: true,
        network: :mainnet
      }}
      iex> privkey_to_wif(binprivkey, compressed: false, network: :testnet)
      {:ok, %{
        wif: "91bRE5Duv5h8kYhhTLhYRXijCiXWSpWwFNX6nndfuntBdPV2idD",
        compressed: false,
        network: :testnet
      }}

  When binary private key has an unexpected length (not 64 bytes for hex
  format or 32 bytes for binary format) returns error:

      iex> privkey_to_wif(<<1, 35, 69>>)
      {:error, :incorrect_privkey_length}

  When private key is out of recommended range will return error:

      iex> maxprivkey = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140" |> Base.decode16!()
      iex> privkey_to_wif(maxprivkey)
      {:error, :ecc_out_range}
  """
  @default_options [network: :mainnet, compressed: true]
  @spec privkey_to_wif( <<_::512>> | <<_::256>>, [{atom, any}] ) ::
    {:ok, wif_type}
    | {:error, atom }
  def privkey_to_wif(privkey, options \\ [])
  def privkey_to_wif(hexprivkey, options) when is_binary(hexprivkey) and bit_size(hexprivkey) === 512 do
    options = Keyword.merge( [case: :mixed], options)
    hexprivkey
    |>Base.decode16!(case: options[:case])
    |>privkey_to_wif(options)
  end
  # Private key must be inside a recommended range. Otherwise return
  # error. More info at:
  # https://bitcoin.stackexchange.com/questions/1389#answer-1715
  def privkey_to_wif(hexprivkey, _options) when hexprivkey <= @ecc_min or hexprivkey >= @ecc_max do
    {:error, :ecc_out_range}
  end
  def privkey_to_wif(binprivkey, options) when is_binary(binprivkey) and bit_size(binprivkey) === 256 do
    options = Keyword.merge(@default_options, options)
    {:ok, PrivKey.to_wif(binprivkey, options[:network], options[:compressed])}
  end
  # If privkey is not binary or have the expected length return error
  def privkey_to_wif(_privkey, _options ) do
    {:error, :incorrect_privkey_length}
  end

end
