const {
  expect
} = require("chai");
const {
  parseEther
} = require("ethers/lib/utils");
const {
  ethers
} = require("hardhat");


describe("Test MetaBeasts", function () {
  it("testOwnedTokens ", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();

    await metaBeasts.founderMint(6);
    console.log(await metaBeasts.getMintedCards())

  });

  it("setURI => (Ownable)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    contractA1 = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[1]);
    metaBeasts.setURI("testURI")
    await expect(contractA1.setURI("testURI"))
      .to.be.revertedWith('Ownable: caller is not the owner');
  });

  it("gift => (Ownable & Balance update & Even & Limit)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    contractA1 = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[1]);


    await metaBeasts.gift([accounts[0].address, accounts[1].address, accounts[2].address, accounts[3].address]);
    await expect(metaBeasts.gift([accounts[0].address])).to.be.revertedWith('NOT_EVEN');
    await expect(contractA1.gift([accounts[0].address, accounts[1].address, accounts[2].address, accounts[3].address])).to.be.revertedWith('Ownable: caller is not the owner');
    expect(await metaBeasts.totalBalanceOf(accounts[0].address)).to.be.equal(1);
    expect(await metaBeasts.totalBalanceOf(accounts[1].address)).to.be.equal(1);
    expect(await metaBeasts.totalBalanceOf(accounts[2].address)).to.be.equal(1);
    expect(await metaBeasts.totalBalanceOf(accounts[3].address)).to.be.equal(1);
    // expect(await metaBeasts.totalSupply()).to.be.equal(4);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(4);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(2); //  chests

    for (let index = 1; index <= 1798; index++) {
      await metaBeasts.gift([accounts[0].address, accounts[1].address]);
    }
    expect(await metaBeasts.totalBalanceOf(accounts[0].address)).to.be.equal(1799);
    expect(await metaBeasts.totalBalanceOf(accounts[1].address)).to.be.equal(1799);
    //  expect(await metaBeasts.totalSupply()).to.be.equal(3600);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(3600);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(1800); //  chests
    await expect(metaBeasts.gift([accounts[0].address, accounts[1].address])).to.be.revertedWith('EXCEED_TEAM_RESERVE');
  });




  it("FounderMint => (Ownable & Balance update & Even & Limit)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    contractA1 = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[1]);

    await metaBeasts.founderMint(2);
    await expect(metaBeasts.founderMint(1)).to.be.revertedWith('NOT_EVEN');
    await expect(contractA1.founderMint(2)).to.be.revertedWith('Ownable: caller is not the owner');
    expect(await metaBeasts.totalBalanceOf(accounts[0].address)).to.be.equal(2);

    // expect(await metaBeasts.totalSupply()).to.be.equal(4);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(2);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(1); //  chests

    for (let index = 1; index <= 1799; index++) {
      await metaBeasts.founderMint(2);
    }
    expect(await metaBeasts.totalBalanceOf(accounts[0].address)).to.be.equal(3600);

    //  expect(await metaBeasts.totalSupply()).to.be.equal(3600);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(3600);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(1800); //  chests
    await expect(metaBeasts.founderMint(2)).to.be.revertedWith('EXCEED_TEAM_RESERVE');
  });







  it("giftChest => (Ownable & Balance update & Limit)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    contractA1 = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[1]);

    await metaBeasts.giftChest([accounts[0].address, accounts[1].address]);
    await expect(contractA1.giftChest([accounts[0].address, accounts[1].address])).to.be.revertedWith('Ownable: caller is not the owner');
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(1);
    expect(await metaBeasts.balanceOf(accounts[1].address, 0)).to.be.equal(1);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(2); //  chests

    for (let index = 1; index <= 899; index++) {
      await metaBeasts.giftChest([accounts[0].address, accounts[1].address]);
    }
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(900);
    expect(await metaBeasts.balanceOf(accounts[1].address, 0)).to.be.equal(900);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(1800); //  chests
    await expect(metaBeasts.giftChest([accounts[0].address])).to.be.revertedWith('EXCEED_TEAM_RESERVE');
  });



  it("founderMintChest => (Ownable & Balance update & Limit)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    contractA1 = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[1]);

    await metaBeasts.founderMintChest(2);
    await expect(contractA1.founderMintChest(2)).to.be.revertedWith('Ownable: caller is not the owner');
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(2);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(2); //  chests

    for (let index = 1; index <= 899; index++) {
      await metaBeasts.founderMintChest(2);
    }
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(1800);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(1800); //  chests
    await expect(metaBeasts.founderMintChest(1)).to.be.revertedWith('EXCEED_TEAM_RESERVE');
  });


  it("buyAndOpenChests => (publicLive & Balance update & Limit & Tx limit & Price)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();

    await expect(metaBeasts.buyAndOpenChests(1)).to.be.revertedWith('MINT_CLOSED');
    await metaBeasts.togglePublicMintStatus();
    await expect(metaBeasts.buyAndOpenChests(1, {
      value: parseEther("0.09999")
    })).to.be.revertedWith('INSUFFICIENT_ETH');
    await expect(metaBeasts.buyAndOpenChests(6, {
      value: parseEther("0.6")
    })).to.be.revertedWith('EXCEED_PER_MINT');


    await metaBeasts.buyAndOpenChests(1, {
      value: parseEther("0.1")
    });
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(0);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(2);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(1);

    for (let index = 1; index <= 5999; index++) {
      await metaBeasts.buyAndOpenChests(1, {
        value: parseEther("0.1")
      });
    }
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(0);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(12000);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(6000);
    await expect(metaBeasts.buyAndOpenChests(1, {
      value: parseEther("0.1")
    })).to.be.revertedWith('EXCEED_PUBLIC');
  });



  it("buyChests => (publicLive & Balance update & Limit & Tx limit & Price)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();

    await expect(metaBeasts.buyChests(1)).to.be.revertedWith('MINT_CLOSED');
    await metaBeasts.togglePublicMintStatus();
    await expect(metaBeasts.buyChests(1, {
      value: parseEther("0.09999")
    })).to.be.revertedWith('INSUFFICIENT_ETH');
    await expect(metaBeasts.buyChests(6, {
      value: parseEther("0.6")
    })).to.be.revertedWith('EXCEED_PER_MINT');


    await metaBeasts.buyChests(1, {
      value: parseEther("0.1")
    });
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(1);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(1);

    for (let index = 1; index <= 5999; index++) {
      await metaBeasts.buyChests(1, {
        value: parseEther("0.1")
      });
    }
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(6000);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(6000);
    await expect(metaBeasts.buyChests(1, {
      value: parseEther("0.1")
    })).to.be.revertedWith('EXCEED_PUBLIC');
  });


  it("openChests => (Balance update & Insufficient chests)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    await expect(metaBeasts.openChests(0)).to.be.revertedWith('NOT_ALLOWED');
    await expect(metaBeasts.openChests(1)).to.be.revertedWith('INSUFFICIENT_CHESTS');
    await metaBeasts.setTeamReserve(10000);

    await metaBeasts.founderMintChest(1);

    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(1);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    await expect(metaBeasts.openChests(2)).to.be.revertedWith('INSUFFICIENT_CHESTS');
    await metaBeasts.openChests(1);

    for (let index = 1; index <= 99; index++) {
      await metaBeasts.founderMintChest(100);
    }
    await metaBeasts.founderMintChest(99);
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(9999);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(2);
    expect(await metaBeasts.teamChestsMinted()).to.be.equal(10000);


    for (let index = 1; index <= 99; index++) {
      await expect(metaBeasts.openChests(100));
    }
    await expect(metaBeasts.openChests(99));
    await expect(metaBeasts.openChests(1)).to.be.revertedWith('INSUFFICIENT_CHESTS');
  });


  it("forge => (Balance update & Insufficient cards & id range)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();


    await metaBeasts.founderMint(1000);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(1000);
    let balance = parseInt(await metaBeasts.balanceOf(accounts[0].address, 84));
    await metaBeasts.burn(accounts[0].address, 1, parseInt(await metaBeasts.balanceOf(accounts[0].address, 1)));

    if (balance > 4) {
      await metaBeasts.burn(accounts[0].address, 84, balance - 4);
    }

    await expect(metaBeasts.forge(1)).to.be.revertedWith('INSUFFICIENT_CARDS');
    await expect(metaBeasts.forge(0)).to.be.revertedWith('INVALID_ID');

    expect(await metaBeasts.balanceOf(accounts[0].address, 84)).to.be.equal(4);

    await expect(metaBeasts.forge(84))

    await expect(metaBeasts.forge(184)).to.be.revertedWith('INSUFFICIENT_CARDS');
    expect(await metaBeasts.balanceOf(accounts[0].address, 84)).to.be.equal(2);
    expect(await metaBeasts.balanceOf(accounts[0].address, 184)).to.be.equal(1);

    await expect(metaBeasts.forge(84))

    expect(await metaBeasts.balanceOf(accounts[0].address, 84)).to.be.equal(0);
    expect(await metaBeasts.balanceOf(accounts[0].address, 184)).to.be.equal(2);
    expect(await metaBeasts.balanceOf(accounts[0].address, 284)).to.be.equal(0);

    await expect(metaBeasts.forge(184))

    expect(await metaBeasts.balanceOf(accounts[0].address, 84)).to.be.equal(0);
    expect(await metaBeasts.balanceOf(accounts[0].address, 184)).to.be.equal(0);
    expect(await metaBeasts.balanceOf(accounts[0].address, 284)).to.be.equal(1);


    await expect(metaBeasts.forge(84)).to.be.revertedWith('INSUFFICIENT_CARDS');
    await expect(metaBeasts.forge(184)).to.be.revertedWith('INSUFFICIENT_CARDS');
    await expect(metaBeasts.forge(284)).to.be.revertedWith('INVALID_ID');


    expect(await metaBeasts.totalTier2Supply()).to.be.equal(0);
    expect(await metaBeasts.totalTier3Supply()).to.be.equal(1);


  });


  it("privateBuy => (privateLive & Balance update & Limit & Tx limit & Price & DirectMint)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    const signer = new ethers.Wallet("a568f59ef53c2995ef4837e2853b4cd09ebe845c78a5e00323ced18cb8b65693");

    let signatureA0 = await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[0].address, "MetaBeasts_PRIVATE"])))
    let signatureA1 = await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[1].address, "MetaBeasts_PRIVATE"])))

    await expect(metaBeasts.privateBuy(1, signatureA0)).to.be.revertedWith('MINT_CLOSED');
    await metaBeasts.togglePrivateStatus();

    await expect(metaBeasts.privateBuy(1, signatureA1, {
      value: parseEther("0.1")
    })).to.be.revertedWith('DIRECT_MINT_DISALLOWED');
    await expect(metaBeasts.privateBuy(1, signatureA0, {
      value: parseEther("0.09999")
    })).to.be.revertedWith('INSUFFICIENT_ETH');
    await expect(metaBeasts.privateBuy(6, signatureA0, {
      value: parseEther("0.6")
    })).to.be.revertedWith('EXCEED_PER_WALLET');


    await metaBeasts.privateBuy(1, signatureA0, {
      value: parseEther("0.1")
    });
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(1);

    await metaBeasts.privateBuy(4, signatureA0, {
      value: parseEther("0.4")
    });
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(5);

    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.privateChestsMinted()).to.be.equal(5);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(0);

    for (let index = 1; index <= 439; index++) {
      currentWallet = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[index]);
      await currentWallet.privateBuy(5, await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[index].address, "MetaBeasts_PRIVATE"]))), {
        value: parseEther("0.5")
      });
      expect(await metaBeasts.balanceOf(accounts[index].address, 0)).to.be.equal(5);
      expect(await metaBeasts.totalSupply(0)).to.be.equal(5 + (index * 5));
    }
    expect(await metaBeasts.totalSupply(0)).to.be.equal(2200);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(0);
    expect(await metaBeasts.privateChestsMinted()).to.be.equal(2200);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(0);

    currentWallet = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[500]);
    await expect(currentWallet.privateBuy(1, await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[500].address, "MetaBeasts_PRIVATE"]))), {
      value: parseEther("0.1")
    })).to.be.revertedWith('EXCEED_PRIVATE');
  });



  it("privateBuyAndOpenChest => (privateLive & Balance update & Limit & Tx limit & Price & DirectMint)", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();
    const accounts = await ethers.getSigners();
    const signer = new ethers.Wallet("a568f59ef53c2995ef4837e2853b4cd09ebe845c78a5e00323ced18cb8b65693");

    let signatureA0 = await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[0].address, "MetaBeasts_PRIVATE"])))
    let signatureA1 = await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[1].address, "MetaBeasts_PRIVATE"])))

    await expect(metaBeasts.privateBuyAndOpenChest(1, signatureA0)).to.be.revertedWith('MINT_CLOSED');
    await metaBeasts.togglePrivateStatus();

    await expect(metaBeasts.privateBuyAndOpenChest(1, signatureA1, {
      value: parseEther("0.1")
    })).to.be.revertedWith('DIRECT_MINT_DISALLOWED');
    await expect(metaBeasts.privateBuyAndOpenChest(1, signatureA0, {
      value: parseEther("0.09999")
    })).to.be.revertedWith('INSUFFICIENT_ETH');
    await expect(metaBeasts.privateBuyAndOpenChest(6, signatureA0, {
      value: parseEther("0.6")
    })).to.be.revertedWith('EXCEED_PER_WALLET');


    await metaBeasts.privateBuyAndOpenChest(1, signatureA0, {
      value: parseEther("0.1")
    });
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(0);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(2);
    expect(await metaBeasts.totalBalanceOf(accounts[0].address)).to.be.equal(2);

    await metaBeasts.privateBuyAndOpenChest(4, signatureA0, {
      value: parseEther("0.4")
    });
    expect(await metaBeasts.balanceOf(accounts[0].address, 0)).to.be.equal(0);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(10);
    expect(await metaBeasts.totalBalanceOf(accounts[0].address)).to.be.equal(10);


    expect(await metaBeasts.privateChestsMinted()).to.be.equal(5);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(0);

    for (let index = 1; index <= 439; index++) {
      currentWallet = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[index]);
      await currentWallet.privateBuyAndOpenChest(5, await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[index].address, "MetaBeasts_PRIVATE"]))), {
        value: parseEther("0.5")
      });
      expect(await metaBeasts.totalBalanceOf(accounts[index].address)).to.be.equal(10);

    }
    expect(await metaBeasts.totalSupply(0)).to.be.equal(0);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(2200 * 2);
    expect(await metaBeasts.privateChestsMinted()).to.be.equal(2200);
    expect(await metaBeasts.publicChestsMinted()).to.be.equal(0);

    currentWallet = await ethers.getContractAt("MetaBeasts", metaBeasts.address, accounts[500]);
    await expect(currentWallet.privateBuyAndOpenChest(1, await signer.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(["address", "string"], [accounts[500].address, "MetaBeasts_PRIVATE"]))), {
      value: parseEther("0.1")
    })).to.be.revertedWith('EXCEED_PRIVATE');
  });


  it("Check Limits/Mints if equal & can't mint more than 20K", async function () {
    const MetaBeasts = await ethers.getContractFactory("MetaBeasts");
    const metaBeasts = await MetaBeasts.deploy();
    await metaBeasts.deployed();

    await metaBeasts.setTeamReserve(10001);
    for (let index = 1; index <= 100; index++) {
      await metaBeasts.founderMint(200)
    }
    for (let index = 1; index < 100; index++) {
      expect(await metaBeasts._Mints(index)).to.be.equal(await metaBeasts._Limits(index));
    }

    await expect(metaBeasts.founderMint(2)).to.be.revertedWith("NO_TOKEN_LEFT");
    expect(await metaBeasts.totalSupply(0)).to.be.equal(0);
    expect(await metaBeasts.totalTier1Supply()).to.be.equal(20000);

  });
});