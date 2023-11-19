class MedalsController < ApplicationController
    require "net/https"
    require "uri"

    @@user_name = ""

    def index
        @name = client.call(contract, "name")
        @symbol = client.call(contract, "symbol")
        @minter = client.call(contract, "getMinterName")
    end

    # NFTを発行するメソッド
    def new
        user_name = @@user_name
        @id = params[:id].to_i
        @minter_name = params[:name]
        from_address = ""
        to_address = ""

        # ウォレットDBからアドレス情報を取得してto_addressに保存
        if User.find_by(name: @minter_name).nil? then # ウォレットがないとき
            key = Eth::Key.new
            to_address = key.address.to_s
            User.create(address: to_address, name: @minter_name)
        else # ウォレットがあるとき
            to_address = User.where(name: @minter_name)[0].address
        end

        # NFTの発行とアドレスの設定
        begin
            client.transact_and_wait(contract, "mint", @id, @minter_name)
            from_address = client.call(contract, "ownerOf", @id)
            client.transact_and_wait(contract, "safeTransferFrom", from_address, to_address, @id)
        rescue => e # 既に発行されている場合はNFT発行を取りやめる
            @minter_name = "メダルは発行済みです"
            return
        end

        # 検索DBにメダル情報を保存する
        Medal.create(tokenid: @id, address: to_address)
        
    end

    # 自身が発行したNFTを確認するメソッド
    def show
        @@user_name = params[:uname]
        #user_name = "user"
        user = User.find_by(name: @@user_name)
        @medals = []

        # メダルの内容を表示する
        if user.nil? then # ユーザーのアドレスが登録されていないとき
            @medals = []
        else # メダルを既に発行してるとき
            # DBからメダルをアドレスから検索する
            medals = Medal.where(address: user.address)
            # medals = Medal.all()

            # メダルを一枚も発行していないとき
            if medals.nil? then
                @medals = []
                return
            end

            # メダル情報をスマートコントラクトから取得して表示する
            for medal in medals do
                token_id = medal.tokenid
                minter_name = client.call(contract, "getMinterName", token_id)
                minter_address = client.call(contract, "ownerOf", token_id)
                image = get_image(token_id)
                @medals.push({"tokenId":token_id,"minter_name":minter_name,"minter_address":minter_address, "image":image})
            end
        end

    end

    # 自分以外のNFTを確認するメソッド
    def list
        user_name = @@user_name
        @medals = []

        my_address = User.find_by(name: user_name).address
        medals = Medal.where.not(address: my_address)

        for medal in medals do
            token_id = medal.tokenid
            minter_name = client.call(contract, "getMinterName", token_id)
            minter_address = client.call(contract, "ownerOf", token_id)
            image = get_image(token_id)
            @medals.push({"tokenId":token_id,"minter_name":minter_name,"minter_address":minter_address, "image":image})
        end
    end

    def exchanged
        user_name = @@user_name

        id = params[:id].to_i
        address = User.find_by(name: user_name).address

        Medal.find_by(tokenid: id).update(address: address)
        client.transact_and_wait(contract, "changeMedalOwner", id, address, user_name)
    end

    private
    def medals_params
        params.require(:medal).permit(:uname)
    end

    def client
        url = ENV.fetch('GETH_URL', 'http://localhost:8545')
        Eth::Client.create url
    end

    def contract
        contract = Eth::Solidity.new.compile contract_file
        Eth::Contract.from_abi(name: contract_name, address: contract_address, abi: contract[contract_name]["abi"].to_json)
    end

    def contract_file
        contract_settings["file"]
    end

    def contract_name
        contract_settings["name"]
    end

    def contract_address
        contract_settings["address"]
    end

    def contract_settings
        JSON.parse(File.read Rails.root.join("contracts/Medal.json"))
    end

    # 画像を取得する関数
    def get_image(id)
        # HTTPクライアントの初期化
        url = URI.parse("https://tama-connect.com/api/page/#{id.to_s}")
        http = Net::HTTP.new(url.host, url.port)
        
        # SSLの有効化
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        # HTTPリクエスト
        request = Net::HTTP::Get.new(url)

        # レスポンスボディをJSONに変換
        response = http.request(request)
        json = JSON.parse(response.body)

        return json["image"]
    end
end
