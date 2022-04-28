# hik_contracts
1. 파일구성
   1. hik_sales.sol
   2. hik_whitelists.sol

3. Deploy 순서
   1. hik_whitelists.sol => hik_sales.sol
   hik_whitelists 를 먼저 배포 한 후, hik_sales 를 배포함

4. 사용방법.
   1. hik_whitelists.sol
      1. 우선 compiler 버전을 0.7이상 0.9 이하로 설정한다.- 버전 0.87에서 테스트함. (pragma solidity >=0.7.0 <0.9.0;)
      2. 순서.
         1. WhiteLists deploy -> HikMintFactory deploy -> WhiteLists.setMinter -> HikMintFactory.setupSale -> HikMintFactory.buyNft
      3. WhiteLists 컨트랙트
         1. 함수
            1. setMinter(address _address)
                -> 민팅을 할 수 있는 지갑 주소 설정 setter.
                -> adminOnly executes
            2. getMinter(address _address)
                ->  민팅을 할 수 있는 지갑 보기 getter
            3. deleteMinter(address _address)
                -> 민팅 권한 삭제.
                -> adminOnly executes
            4. getAdmin(address _address)
                -> 어드민 계정 보기 getter
            5. setAdmin(address _address)
                -> 어드민 계정 설정 setter
                -> ownerOnly execute (컨트랙트 오너만 실행 가능)
            6. deleteAdmin(address _address)
                -> 어드민 계정 삭제.
                -> ownerOnly execute (컨트랙트 오너만 실행 가능)
            7. pause()
                -> 컨트랙트 기능 정지 (응급사항)
                -> ownerOnly execute (컨트랙트 오너만 실행 가능)
            8. unpause()
                -> 컨트랙트 기능 resume
                -> ownerOnly execute (컨트랙트 오너만 실행 가능)
      4. HikMintFactory 컨트랙트
         1. Logic.
            1. 같은 NFT가 여러개 Mint를 해야하기 때문에, groupId라는것을 설정. 기본적인 정보는 groupId 안에 저장되고 (metadata, 로얄티, 판매가격, 등등) 같은 정보의 다른 NFT가 minting 됨. 이때 민팅된 NFT는 tokenId로 개별적인 아이디로 적용되며, getNftTokenToGroupId 함수를 통해서 tokenId로 groupId를 알 수 있다.
            2. groupId를 먼저 생성을 해서 기본정보를 저장한 후, minting이 가능하다.
            3. minting은 구매자가 가스비를 내게되며, buyNft 함수를 통해서 mint -> transfer -> 자금분배가 이루어진다.
         2. 함수
            1. getServiceFee()
               -> return : uint256
               -> 서비스 비용 % getter
            2. setServiceFee(uint256 _newServiceFee)
                -> 서비스 비용 %  setter
                -> default value 500 (5%)
                -> solidity 는 float 및 double 을 지원하지 않기 때문에, 아래와 같이 % 값을 설정함.
               10000 => 100%, 1000=>10%, 500 => 5%, 100 => 1%
            3. getGroupOwner(uint256 _groupId)
               -> return : address
               -> group owner address 리턴. getter
            4. getOriginalGroup(uint256 _groupId)
               -> return : uint256
               -> 원작자 groupId를 리턴. getter
            5. getSalePrice(uint256 _groupId)
               -> return : uint256
               -> 판매 가격을 리턴. getter
               -> 단위는 wei.(1000000000000000000 wei = 1 matic) 비슷한 원리로 폴리곤도 이더리움과 같은 conversion 을 가진다.
               (https://www.cryps.info/en/Wei_to_ETH/1/)
            6. setSalePrice(uint256 _groupId, uint256 _price)
               -> 판매 가격 세팅. setter
               -> 단위는 wei 5번 참고.
               -> adminOnly executes
            7. getLoyalty(uint256 _groupId)
               -> return : uint256
               -> 로얄티 % 리턴. getter
               ->10000 => 100%, 1000=>10%, 500 => 5%, 100 => 1%. 2번 참고.
            8. setLoyalty(uint256 _groupId, uint256 _loyalty)
               ->로얄티 % 세팅 .setter
               ->adminOnly executes
               -> _loyalty value :10000 => 100%, 1000=>10%, 500 => 5%, 100 => 1%. 2번 참고.
            9. getMetaData(uint256 _groupId)
               ->return: string
               -> 메타데이타 url정보 리턴. getter
            10. setMetaData(uint256 _groupId, string memory _uri)
                -> 메타데이타 url 세팅. setter
                ->adminOnly executes
            11. getSaleStatus(uint256 _groupId)
                -> return:bool
                -> 판매중 또는 판매 정지. getter
            12. setSaleStatus(uint256 _groupId, bool _status)
                -> 판매 status 설정. true -> 판매중, false -> 판매 중지 및 금지. setter
                -> adminOnly executes or groupOwner executes
            13. getMintAmount(uint256 _groupId)
                -> return: uint256
                -> 민팅 허용 갯수. getter
            14. setMintAmount(uint256 _groupId, uint256 _amounts)
                -> 민팅 허용 갯수 세팅. setter
                -> adminOnly executes
            15. getSoldAmount(uint256 _groupId)
                ->return: uint256
                -> 판매 갯수. getter
            16. getNftTokenToGroupId(uint256 _nftTokenId)
                -> return: uint256
                -> tokenId point to groupId. getter
                -> nft 판매가 완료된 후, nft token id와 group id 를 맵핑
            17. setupSale(uint256 _groupId,uint256 _originalGroupId,address _groupOwner, uint256 _price,uint256 _loyalty, uint256 _mintAmounts ,string memory _metadataUri)
                -> 판매 허가 후, 판매를 시작한다고 세팅. setter.
                -> adminOnly executes
                -> 재창작물이 아닌경우, _originalGroupId =0 , 재창작물일 경우, _originalGroupId 는 원창작물의 그룹아이디를 넣는다.
                -> ex) 1. 원창작물 : setupSale(1,0,0x2FCC7b6400eD578C1bEBBEaC35eed342660a58EC,100000000000000000,550,100,"ipfs://QmVoW4fKmEHcf6Zs1GoisoJ1E2RuzsNBuXGfwBhN2RcNxQ/99.png")
                -> ex) 2. 재창작물 : setupSale(2,1,0x638c3cd87c92538e803E4983443c415441b0b5A8,100000000000000000,0,100,"ipfs://QmVoW4fKmEHcf6Zs1GoisoJ1E2RuzsNBuXGfwBhN2RcNxQ/100.png")
            18. buyNft(uint256 _groupId)
                -> Nft 판매.
                -> 구매자는 groupID 의 getSalePrice(5번) 보다 높은 matic을 보낼수 있게 msg.value 를 설정.
                -> 모든 설정이 끝나면, 구매자의 msg.value의 값이. 1. 서비스 비용 %(getServiceFee() 1번) 2. loyalty % (getLoyalty(getOriginalGroup(_groupId))) 원작자가 지정한 로얄티 %, 3. 앞에 service fee 와 loyalty를 제거한 금액 으로 계산됨.
                -> 판매자, 원작자에게 matic은 분배가 되며, 나머지 service fee 는 HikMintFactory 안에 남게된다.
                -> 민팅 후, 구매자 주소로 nft 전송.
                -> emit Deposit 를 통해서 log를 main_net 안에 남긴다.
                -> return:uint256 -> 새로운 token Id를 리턴함.
            19. withdraw()
                -> 컨트랙트에 저장되어있는 serviceFee를 인출한후, 컨트랙트 owner 지갑주소로 전송.
                -> adminOnly executes
            20. totalSupply()
                -> return:uint256
                -> 총 nft 발행 갯수.
            21. burn(uint256 _burnTokenId)
                -> nft 토큰 삭제.
                -> adminOnly executes or tokenHolder(토큰 소유자) executes

            22. balance()
                -> return: uint256
                -> 컨트랙 안에 servicefee 조회.


