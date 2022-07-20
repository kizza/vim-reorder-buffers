import assert from "assert";
import bootVim, {getBuffer, NeovimClient, setBuffer, WithVim} from "nvim-test-js";
import * as path from "path";

const testDirecotry = path.resolve(__dirname, "buffers");

const switchDirectory = async (nvim: NeovimClient) => {
  nvim.commandOutput(`execute("cd ${testDirecotry}")`);
  return nvim;
}

const withVim = (test: WithVim) =>
  bootVim(nvim =>
    Promise.resolve(nvim)
      .then(switchDirectory)
      .then(test)
  )

const currentBuffer = async (nvim: NeovimClient) =>
  await nvim.commandOutput('echo expand("%")')

const bufferList = async (nvim: NeovimClient) =>
  Promise.resolve<{bufnr: number}[]>(nvim.call('getbufinfo'))
    .then(buffers => buffers.map(buffer => buffer["bufnr"]))
    .then(bufnrs => bufnrs.map(bufnr => nvim.commandOutput(`echo expand("#${bufnr}:%")`)))
    .then(promises => Promise.all(promises))

describe("vim-reorder-buffers", () => {
  describe("loading buffers", () => {
    it("can load a test buffer", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        const lines = await nvim.buffer.getLines()
        assert.equal(lines.join(""), "A")
      }));
  });

  describe("basic shifting", () => {
    it("it shifts middle to the left", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        await nvim.command('edit B.txt')
        await nvim.command('edit C.txt')
        await nvim.command('bprev')
        assert.deepEqual(await bufferList(nvim), ["A.txt", "B.txt", "C.txt"])
        assert.equal(await currentBuffer(nvim), "B.txt")

        await nvim.command('ShiftBufferLeft')
        assert.deepEqual(await bufferList(nvim), ["B.txt", "A.txt", "C.txt"])
        assert.equal(await currentBuffer(nvim), "B.txt")
      }));

    it("it shifts middle to the right", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        await nvim.command('edit B.txt')
        await nvim.command('edit C.txt')
        await nvim.command('bprev')
        assert.deepEqual(await bufferList(nvim), ["A.txt", "B.txt", "C.txt"])
        assert.equal(await currentBuffer(nvim), "B.txt")

        await nvim.command('ShiftBufferRight')
        assert.deepEqual(await bufferList(nvim), ["A.txt", "C.txt", "B.txt"])
        assert.equal(await currentBuffer(nvim), "B.txt")
      }));
  });

  describe("edge shifting", () => {
    it("it shifts first to the end", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        await nvim.command('edit B.txt')
        await nvim.command('edit C.txt')
        await nvim.command('bfirst')
        assert.deepEqual(await bufferList(nvim), ["A.txt", "B.txt", "C.txt"])
        assert.equal(await currentBuffer(nvim), "A.txt")

        await nvim.command('ShiftBufferLeft')
        assert.deepEqual(await bufferList(nvim), ["B.txt", "C.txt", "A.txt"])
        assert.equal(await currentBuffer(nvim), "A.txt")
      }));

    it("it shifts last round to first", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        await nvim.command('edit B.txt')
        await nvim.command('edit C.txt')
        assert.deepEqual(await bufferList(nvim), ["A.txt", "B.txt", "C.txt"])
        assert.equal(await currentBuffer(nvim), "C.txt")

        await nvim.command('ShiftBufferRight')
        assert.deepEqual(await bufferList(nvim), ["C.txt", "A.txt", "B.txt"])
        assert.equal(await currentBuffer(nvim), "C.txt")
      }));
  });

  describe("unsaved buffers", () => {
    it("it does nothing is a buffer is modified", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        await nvim.command('edit B.txt')
        assert.deepEqual(await bufferList(nvim), ["A.txt", "B.txt"])

        await nvim.buffer.append("a change")
        await nvim.command('ShiftBufferLeft')
        await nvim.command('ShiftBufferRight')

        assert.deepEqual(await bufferList(nvim), ["A.txt", "B.txt"])
      }));

    it("will auto save if allowed to do so", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        await nvim.command('edit B.txt')
        assert.deepEqual(await bufferList(nvim), ["A.txt", "B.txt"])

        await nvim.buffer.append("a change")
        await nvim.command("let g:reorder_buffers_allow_auto_save = v:true")
        await nvim.command('ShiftBufferRight')

        assert.deepEqual(await bufferList(nvim), ["B.txt", "A.txt"])

        await setBuffer(nvim, "B")
        await nvim.command("w")
        assert.equal(await getBuffer(nvim), ["B"])
      }));
  })

  describe("noops", () => {
    it("it does nothing with a single buffer", () =>
      withVim(async nvim => {
        await nvim.command('edit A.txt')
        assert.deepEqual(await bufferList(nvim), ["A.txt"])
        assert.equal(await currentBuffer(nvim), "A.txt")

        const bufferNumber = () => nvim.commandOutput("echo winbufnr(0)")
        const originalBufferNumber = await bufferNumber()
        await nvim.command('ShiftBufferLeft')
        await nvim.command('ShiftBufferRight')

        assert.deepEqual(await bufferList(nvim), ["A.txt"])
        assert.equal(await currentBuffer(nvim), "A.txt")
        assert.equal(await bufferNumber(), originalBufferNumber)
      }));
  })
})
