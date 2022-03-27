const { expect } = require('chai');

const SharedWallet = artifacts.require('SharedWallet');
const SharedWalletFactory = artifacts.require('SharedWalletFactory');
const SharedWalletsStorage = artifacts.require('SharedWalletsStorage');


contract('SharedWalletsStorage', function (accounts) {
    const [creator, newMember, nonMember] = accounts;
    const nullAddress = "0x0000000000000000000000000000000000000000";
    const name = "test";

    beforeEach(async function () {
        this.factory = await SharedWalletFactory.new();

        this.storageAddr = await this.factory.walletsStorage();
        this.storage = await SharedWalletsStorage.at(this.storageAddr);

        await this.factory.createNewSharedWallet(name, { from: creator });
        this.walletAddr = await this.factory.lastWalletCreated();
        this.wallet = await SharedWallet.at(this.walletAddr);

    });

    it('should pass correct properties to newly created wallet', async function () {
        expect(await this.wallet.name()).to.equal(name);
        expect((await this.wallet.members())[0]).to.equal(creator);
        expect(await this.wallet.walletsStorage()).to.equal(this.storageAddr);
    });

    it('should add wallets to member\'s list', async function () {
        await this.wallet.createRequest(0, 0, newMember, { from: creator });
        const requestId = (await this.wallet.requestsCounter()) - 1;
        await this.wallet.acceptInvitation(requestId, { from: newMember });
        expect((await this.storage.userWallets({ from: newMember }))[0]).to.equal(this.walletAddr);
    });

    it('should remove wallets from member\'s list', async function () {
        await this.wallet.createRequest(1, 0, creator, { from: creator });
        expect((await this.storage.userWallets({ from: creator })).length).to.equal(0);
    });

    describe('Only wallet members', function () {
        it('should be able to add wallet address in their own list', async function () {
            // they
            await this.wallet.createRequest(0, 0, newMember, { from: creator });
            const requestId = (await this.wallet.requestsCounter()) - 1;
            await this.wallet.acceptInvitation(requestId, { from: newMember });

            expect((await this.storage.userWallets({ from: newMember }))[0]).to.equal(this.walletAddr);

            // others
            try {
                await this.storage.addWalletToUser(this.walletAddr, nonMember);
                expect.fail();
            } catch (err) { }
        });

    });

    describe('Only not wallet members', function () {
        it('should be able to remove wallet address from their own list', async function () {
            // others
            try {
                await this.storage.removeWalletForUser(this.walletAddr, creator, { from: nonMember });
                expect.fail();
            } catch (err) {
            }

            // they
            await this.wallet.createRequest(1, 0, creator, { from: creator });

            expect((await this.storage.userWallets({ from: creator })).length).to.equal(0);
        });
    });
});