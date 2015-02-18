PinController = require '../../app/controllers/pin-controller'

describe 'PinController', ->
  beforeEach ->
    @uuid = 'uuid1'
    @meshblu = {}
    @pinModel = {}
    @dependencies = meshblu : @meshblu, pinModel: @pinModel
    @sut = new PinController @uuid, @dependencies

  describe 'constructor', ->
    it 'should instantiate a PinController', ->
      expect(@sut).to.exist

  describe 'create device', ->
    it 'should should exist', ->
      expect(@sut.createDevice).to.exist

    describe 'when called', ->
      beforeEach ->
        @meshblu.register = sinon.stub()
        @sut.createDevice()

      it 'should call register on meshblu', ->
        expect(@meshblu.register).to.have.been.called;

      it 'should add its uuid to a configure whitelist', ->
        expect(@meshblu.register.firstCall.args[0].configureWhitelist).to.deep.equal [@uuid]

    describe 'when PinController was constructed with a different uuid', ->
      beforeEach ->
        @uuid = 'uuid2'
        @sut = new PinController @uuid, @dependencies
        @meshblu.register = sinon.stub()

      describe 'when createDevice is called', ->
        beforeEach ->
          @sut.createDevice()

        it 'should call meshblu.register with the uuid in the whitelist', ->
          expect(@meshblu.register).to.have.been.calledWith configureWhitelist: [@uuid]

      describe 'when createDevice is called with some device properties', ->
        beforeEach ->
          @sut.createDevice '1234', foo: 'bar'

        it 'should call meshblu.register device properties merged in', ->
          expect(@meshblu.register).to.have.been.calledWith configureWhitelist: [@uuid], foo: 'bar'

      describe 'when createDevice is called with a configureWhitelist', ->
        beforeEach ->
          @sut.createDevice '1234', configureWhitelist: ['73d0f6da-4b5d-4880-9f78-f48ed1b51704']

        it 'should call meshblu.register device properties merged in', ->
          expect(@meshblu.register).to.have.been.calledWith configureWhitelist: ['73d0f6da-4b5d-4880-9f78-f48ed1b51704', @uuid]

  describe 'when register yields a new device', ->
    beforeEach ->
      @uuid = 'ferk'
      @pin = 'werms'
      @meshblu.register = sinon.stub().yields { uuid: @uuid }
      @pinModel.save = sinon.stub()
      @sut.createDevice @pin, {}

    it 'it should save the uuid and pin combination', ->
      expect(@pinModel.save).to.have.been.calledWith @uuid, @pin

  describe 'when register yields a different device and save yields', ->
    beforeEach (done) ->
      @callback = sinon.stub()
      @uuid = 'fark'
      @pin = 'warms'
      @meshblu.register = sinon.stub().yields { uuid: @uuid }
      @pinModel.save = sinon.stub().yields(null)
      @sut.createDevice @pin, null, (error, @result) => done()

    it 'it should save that uuid and pin combination', ->
      expect(@pinModel.save).to.have.been.calledWith @uuid, @pin

    it 'should yield the uuid', ->
      expect(@result).to.equal @uuid

  describe 'when register yields a different different device', ->
    beforeEach ->
      @callback = sinon.stub()
      @uuid = 'fork'
      @pin = 'worms'
      @meshblu.register = sinon.stub().yields { uuid: @uuid }
      @pinModel.save = sinon.stub().yields(null)
      @sut.createDevice @pin, null, @callback

    it 'it should save that uuid and pin combination', ->
      expect(@pinModel.save).to.have.been.calledWith @uuid, @pin

    it 'should call the callback with the uuid', ->
      expect(@callback).to.have.been.calledWith null, @uuid


  describe 'getToken', ->
    beforeEach ->
      @pinModel.checkPin = sinon.stub()

    it 'should exist', ->
      expect(@sut.getToken).to.exist

    describe 'when called', ->
      beforeEach ->
        @uuid = 'banana'
        @pin = 'split'
      it 'should call pinModel.checkPin', ->
        @sut.getToken @uuid, @pin
        expect(@pinModel.checkPin).to.have.been.calledWith @uuid, @pin

      describe 'and the pin is valid', ->
        beforeEach ->
          @pinModel.checkPin.yields null, true
          @meshblu.generateAndStoreToken = sinon.stub()

        it 'it should get a session token from meshblu', ->
          @sut.getToken @uuid, @pin
          expect(@meshblu.generateAndStoreToken).to.have.been.calledWith uuid: @uuid

    describe 'when called with a different uuid & pin', ->
      beforeEach ->
        @uuid = 'ice cream'
        @pin = 'sundae'

      it 'should call pinModel.checkPin with those params', ->
        @sut.getToken @uuid, @pin
        expect(@pinModel.checkPin).to.have.been.calledWith @uuid, @pin

      describe 'and the pin causes checkPin to error', ->
        beforeEach ->
          @pinModel.checkPin.yields true
          @callback = sinon.stub()

        it 'should call the callback with an error', ->
          @sut.getToken @uuid, @pin, @callback
          expect(@callback.args[0][0]).to.exist

      describe 'and the pin is invalid', ->
        beforeEach ->
          @pinModel.checkPin.yields null, false
          @callback = sinon.stub()

        it 'should call the callback with an error', ->
          @sut.getToken @uuid, @pin, @callback
          expect(@callback.args[0][0]).to.exist

      describe 'and the pin is valid', ->
        beforeEach ->
          @pinModel.checkPin.yields null, true
          @meshblu.generateAndStoreToken = sinon.stub()

        it 'it should get a session token from meshblu', ->
          @sut.getToken @uuid, @pin
          expect(@meshblu.generateAndStoreToken).to.have.been.calledWith uuid: @uuid

        describe 'and meshblu.generateAndStoreToken yields token', ->
          beforeEach (done) ->
            @meshblu.generateAndStoreToken.yields token: 'bombastic'
            @sut.getToken @uuid, @pin, (@error, @result) => done()

          it 'call callback with the error', ->
            expect(@result.token).to.equal 'bombastic'

