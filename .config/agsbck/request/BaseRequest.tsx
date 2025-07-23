export default class BaseRequest {
    command: string | undefined

    public async execute(request: string, res: (response: any) => void) {
        const params = request.split(" ")

        if(params[0] !== this.command) {
            return
        }

        params.shift()

        await this.handleCommand(params, res)


    }

    async handleCommand(params: string[], res: (response: any) => void) {

    }
}