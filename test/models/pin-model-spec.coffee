PinModel = require '../../app/models/pin-model'

describe 'PinModel', ->
  beforeEach ->
    @db = {}
    @bcrypt = {}
    @dependencies = db: @db, bcrypt: @bcrypt
    @sut = new PinModel @dependencies

  describe 'constructor', ->
    it 'should instantiate a PinModel', ->
      expect(@sut).to.exist

  describe 'checkPin method', ->
    it 'should exist', ->
      expect(@sut.checkPin).to.exist

    describe 'when called with a uuid and pin', ->
      beforeEach ->
        @uuid = "toucan"
        @uuid2 = "uncle"
        @pin = "sam"
        @db.findOne = sinon.stub()

      it 'should call db.findOne with that token', ->
        @sut.checkPin @uuid, @pin
        expect(@db.findOne).to.have.been.calledWith uuid: @uuid

      describe 'and we can\'t find one', ->
        beforeEach ->
          @db.findOne.yields true
          @callback = sinon.stub()

        it 'should call the callback with an error', ->
          @sut.checkPin @uuid, @pin, @callback
          expect(@callback.args[0][0]).to.exist

      describe 'and we can find one', ->
        beforeEach ->
          @hash = 'green eggs and ham'
          @db.findOne.yields null, pin: @hash
          @callback = sinon.stub()
          @bcrypt.compare = sinon.stub()

        it 'check if the hash of the pin is good.', ->
          @sut.checkPin @uuid, @pin, @callback
          expect(@bcrypt.compare).to.have.been.calledWith @pin, @hash

      describe 'and we can find a different one', ->
        beforeEach ->
          @pin2 ='Frodo'
          @hash2 = 'Baggins'
          @db.findOne.yields null, pin: @hash2
          @callback = sinon.stub()
          @bcrypt.compare = sinon.stub()

        it 'check if the hash of that pin is good.', ->
          @sut.checkPin @uuid, @pin2, @callback
          expect(@bcrypt.compare).to.have.been.calledWith @pin2, @hash2

        describe 'and bcrypt.compare yields an error', ->
          beforeEach ->
            @bcrypt.compare.yields true

          it 'should call the callback with an error', ->
             @sut.checkPin @uuid, @pin2, @callback
             expect(@callback.args[0][0]).to.exist


      it 'should call db.findOne with some other token', ->
        @sut.checkPin @uuid2, @pin
        expect(@db.findOne).to.have.been.calledWith uuid: @uuid2

  describe 'save method', ->
    it 'should exist', ->
      expect(@sut.save).to.exist

    describe 'when called with a uuid and a pin', ->
      beforeEach ->
        @uuid = 'Count'
        @pin = 'Chocula'
        @bcrypt.hash = sinon.stub()

      it 'should call bcrypt.hash on the pin', ->
        @sut.save @uuid, @pin
        expect(@bcrypt.hash).to.have.been.calledWith @pin, null, null

      describe 'when bcrypt.hash yields an error', ->
        beforeEach ->
          @callback = sinon.stub()
          @bcrypt.hash.yields true

        it 'should call the callback with an error', ->
          @sut.save @uuid, @pin, @callback
          expect(@callback.args[0][0]).to.exist

      describe 'when bcrypt.hash succeeds', ->
        beforeEach ->
          @callback = sinon.stub()
          @hash = 'chocolate'
          @bcrypt.hash.yields null, @hash
          @db.insert = sinon.stub()

        it 'should call db.insert with an object that has UUID and hash and also the callback', ->
          @sut.save @uuid, @pin, @callback
          expect(@db.insert).to.have.been.calledWith { uuid: @uuid, pin: @hash }, @callback

    describe 'when called with a different uuid and pin', ->
      beforeEach ->
        @uuid = 'Sweedish'
        @pin = 'Chef'
        @bcrypt.hash = sinon.stub()

      it 'should call bcrypt.hash on the pin', ->
        @sut.save(@uuid, @pin)
        expect(@bcrypt.hash).to.have.been.calledWith @pin, null

      describe 'when bcrypt.hash succeeds', ->
        beforeEach ->
          @callback = sinon.stub()
          @hash = 'meatballs'
          @bcrypt.hash.yields null, @hash
          @db.insert = sinon.stub()

        it 'should call db.insert with an object that has UUID and hash and also the callback', ->
          @sut.save @uuid, @pin, @callback
          expect(@db.insert).to.have.been.calledWith { uuid: @uuid, pin: @hash }, @callback

